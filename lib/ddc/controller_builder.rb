module DDC
  class ControllerBuilder
    DEFAULT_CONTEXT_PARAMS = [:params]
    DEFAULT_STATUSES = {
      ok: 200,
      created: 201,
      not_found: 404,
      not_allowed: 401,
      error: 500,
      not_valid: 422,
      deleted: 204
    }
    class << self
      def build(controller_name, config)
        klass = find_or_create_class(controller_name)
        setup_before_actions!(klass, config)
        setup_actions!(controller_name, klass, config)
        klass
      end


      def find_or_create_class(controller_name)
        controller_klass_name = controller_name.to_s.camelize+'Controller'
        klass = nil
        if Object.qualified_const_defined?(controller_klass_name)
          klass = Object.qualified_const_get(controller_klass_name)
        else
          klass = Class.new(ApplicationController)
          Object.qualified_const_set(controller_klass_name, klass)
        end
      end

      def setup_before_actions!(klass, config)
        (config[:before_actions] || []).each do |ba|
          klass.before_action ba
        end
      end

      def setup_actions!(controller_name, klass, config)
        actions = config[:actions]
        raise "Must specify actions" if actions.blank?

        actions.each do |action, action_desc|
          setup_action! controller_name, klass, action, action_desc, config
        end
      end

      def setup_action!(controller_name, klass, action, action_desc, config)
        raise "Must specify a service for each action" unless action_desc[:service].present?
        raise "Must specify a context for each action" unless action_desc[:context].present?
        proc_klass, proc_method = parse_class_and_method(action_desc[:service])
        context_klass, context_method = parse_class_and_method(action_desc[:context])

        klass.send :define_method, action do
          context_params = (action_desc[:context_params] || config[:context_params] || DEFAULT_CONTEXT_PARAMS).inject({}) do |h, param|
            h[param] = send param
            h
          end
          context = context_klass.new.send(context_method, context_params)

          result = proc_klass.new.send(proc_method, context)
          obj = result[:object]
          errors = result[:errors] || []
          plural_model_name = controller_name.to_s
          model_name = plural_model_name.singularize

          # alias in object as model name
          if obj.is_a? Enumerable
            result[plural_model_name] ||= obj
          else
            result[model_name] ||= obj
          end

          status = DEFAULT_STATUSES.merge(action_desc[:status]||{})[result[:status]]

          respond_to do |format|
            format.json do
              if obj.nil?
                render_opts = {
                  json: {errors: errors}, status: status }
              else
                render_opts = { json: obj, status: status }
              end

              render_opts = (action_desc[:render_opts]).merge(render_opts) if action_desc.has_key? :render_opts
              render render_opts
            end
            format.html do
              result.each do |k,v|
                instance_variable_set("@#{k}", v)
              end
            end
          end
        end
      end

      def parse_class_and_method(str)
        under_klass, method = str.split('#')
        [Object.const_get(under_klass.camelize), method]
      end
    end
  end

end
