module DDC
  module ResponseBuilder
    def not_found
      {status: :not_found}
    end

    def ok(obj)
      {status: :ok, object: obj}
    end

    def created(obj)
      {status: :created, object: obj}
    end

    def not_valid(obj)
      {status: :not_valid, errors: obj.errors.to_hash}
    end

    def deleted(obj)
      {status: :deleted}
    end
  end
end
