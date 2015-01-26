module DDC
  class ServiceBuilder
    def self.build(model_type)
      Class.new do
        include DDC::ResponseBuilder
        class << self
          attr_accessor :model_type, :ar_model, :finder
        end

        @model_type = model_type
        ar_class_name = model_type.to_s.camelize
        @ar_model = Object.const_get(ar_class_name)

        @finder = nil
        begin
          @finder = Object.const_get("#{ar_class_name}Finder")
        rescue NameError
          # we use the AR Model as a fallback 
        end

        def find(context)
          id = context[:id]
          me = custom_finder ? custom_finder.find(context) : 
                               ar_model.where(id: id)
          if me.present?
            ok(me)
          else
            not_found
          end
        end

        def find_all(context={})
          mes = custom_finder ? custom_finder.find_all(context) : 
                                ar_model.all
          ok(mes)
        end

        def update(context)
          id, updates = context.values_at :id, self.class.model_type
          me = self.class.ar_model.where id: id

          if me.present?
            me.update_attributes translated_updates
            ok(me)
          else
            not_found
          end
        end

        def create(context)
          attributes = context.values_at self.class.model_type
          me = self.class.ar_model.create attributes
          created(me)
        end

        private
        def custom_finder
          self.class.finder
        end

        def ar_model
          self.class.ar_model
        end

      end
    end
  end
end
