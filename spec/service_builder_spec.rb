require 'spec_helper'

describe DDC::ServiceBuilder do
  subject { described_class }

  describe '.build' do
    before do
      Object.send(:remove_const, :FooFinder) if defined? FooFinder
    end

    class Foo
    end

    it 'defines a class that responds to CRUD' do
      foo_service_klass = subject.build :foo
      service = foo_service_klass.new
      expect(service).to respond_to(:find)
      expect(service).to respond_to(:find_all)
      expect(service).to respond_to(:update)
      expect(service).to respond_to(:create)
    end

    describe '#find' do
      it 'uses the AR model by default and returns DDC status hash' do
        foo_service_klass = subject.build :foo
        service = foo_service_klass.new

        expect(Foo).to receive(:where).with(id: 'monkey').and_return :myfoo
        found_data = service.find({id: 'monkey'})
        expect(found_data[:object]).to eq(:myfoo)
        expect(found_data[:status]).to eq(:ok)
      end

      it 'returns a not_found status' do
        foo_service_klass = subject.build :foo
        service = foo_service_klass.new

        expect(Foo).to receive(:where).with(id: 'monkey').and_return nil
        found_data = service.find({id: 'monkey'})
        expect(found_data[:object]).to eq(nil)
        expect(found_data[:status]).to eq(:not_found)
      end

      it 'uses the FooFinder if present' do
        FooFinder = Class.new
        foo_service_klass = subject.build :foo
        service = foo_service_klass.new

        expect(FooFinder).to receive(:find).with(id: 'monkey').and_return :myfoo
        found_data = service.find({id: 'monkey'})
        expect(found_data[:object]).to eq(:myfoo)
        expect(found_data[:status]).to eq(:ok)
      end
    end

    describe '#find_all' do
      it 'uses the AR model by default and returns DDC status hash' do
        foo_service_klass = subject.build :foo
        service = foo_service_klass.new

        expect(Foo).to receive(:all).and_return :myfoo
        found_data = service.find_all
        expect(found_data[:object]).to eq(:myfoo)
        expect(found_data[:status]).to eq(:ok)
      end

      it 'uses the FooFinder if present' do
        FooFinder = Class.new
        foo_service_klass = subject.build :foo
        service = foo_service_klass.new

        expect(FooFinder).to receive(:find_all).with(user: 'monkey').and_return :myfoo
        found_data = service.find_all({user: 'monkey'})
        expect(found_data[:object]).to eq(:myfoo)
        expect(found_data[:status]).to eq(:ok)
      end
    end
  end
end

