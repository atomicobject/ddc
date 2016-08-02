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
        klass = find_or_create_class(controller_name, config)
        setup_before_actions!(klass, config)
        setup_actions!(controller_name, klass, config)
        klass
      end

 
      def specific_const_defined?(path)
        path.split("::").inject(Object) do |mod, name|
          return unless mod.const_defined?(name, false)
          mod.const_get(name, false)
        end
        return true
      end

      def specific_const_get(path)
        path.split("::").inject(Object) do |mod, name|
          mod.const_get(name, false)
        end
      end

      def specific_const_set(path, klass)
        path_pieces = path.split("::")
        mod_name = path_pieces[0..-2].join("::")
        mod = mod_name.present? ? Object.const_get(mod_name) : Object
        mod.const_set(path_pieces.last, klass)
      end

      def find_or_create_class(controller_name, config)
        controller_klass_name = controller_name.to_s.camelize+'Controller'
        klass = nil
        if specific_const_defined?(controller_klass_name)
          klass = specific_const_get(controller_klass_name)
        else
          parent_klass = config[:parent] || ApplicationController
          klass = Class.new(parent_klass)
          specific_const_set(controller_klass_name, klass)
        end
        klass
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

      def reduce_contexts(contexts, context_params)
        computed_contexts = contexts.map do |context_klass, context_method|
          context_klass.new.send(context_method, context_params)
        end
        if computed_contexts.size == 1
          computed_contexts.first
        else
          computed_contexts.reduce({}) do |h, ctx|
            h.merge(ctx)
          end.with_indifferent_access
        end
      end

      def setup_action!(controller_name, klass, action, action_desc, config)
        raise "Must specify a service for each action" unless action_desc[:service].present?
        raise "Must specify a context for each action" unless (action_desc[:context].present? || action_desc[:contexts].present?)
        proc_klass, proc_method = parse_class_and_method(action_desc[:service])
        contexts = (action_desc[:contexts] || [action_desc[:context]]).map { |ctx| parse_class_and_method ctx }
        #context_klass, context_method = parse_class_and_method(action_desc[:context])

        klass.send :define_method, action do
          context_params = (action_desc[:context_params] || config[:context_params] || DEFAULT_CONTEXT_PARAMS).inject({}) do |h, param|
            h[param] = send param
            h
          end
          context = DDC::ControllerBuilder.reduce_contexts contexts, context_params

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
                render_opts = { json: {errors: errors}, status: status }
                render_opts.reverse_merge!(action_desc[:error_render_opts]) if action_desc.has_key? :error_render_opts
              else
                render_opts = { json: obj, status: status }
                render_opts.reverse_merge!(action_desc[:object_render_opts]) if action_desc.has_key? :object_render_opts
              end

              render_opts.reverse_merge!(action_desc[:render_opts]) if action_desc.has_key? :render_opts
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
