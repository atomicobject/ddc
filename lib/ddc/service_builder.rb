module DDC
  class ServiceBuilder
    def self.build(model_type)
      Class.new  do
        include ResponseBuilder
        class << self
          attr_accessor :model_type, :ar_model
        end

        @model_type = model_type
        ar_class_name = model_type.to_s.camelize
        @ar_model = Object.const_get(ar_class_name)

        def find(context)
          id = context.values_at :id
          me = self.class.ar_model.where id: id
          if me.present?
            ok(me)
          else
            not_found
          end
        end

        def find_all(context)
          mes = self.class.ar_model.all
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
        def find_for_user(user, id)
          return nil if id.nil? || !UUIDUtil.valid?(id)
        end
      end
    end
  end
end
