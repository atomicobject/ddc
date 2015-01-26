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
  end
end
