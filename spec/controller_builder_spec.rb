require 'spec_helper'

describe DDC::ControllerBuilder do
  subject { described_class }

  describe '.build_controller' do
    let(:json_format) {
      format = double('json format')
      expect(format).to receive(:json).and_yield
      expect(format).to receive(:html)
      format }
    let(:html_format) {
      format = double('html format')
      expect(format).to receive(:html).and_yield
      expect(format).to receive(:json)
      format }
    after do
      klass_to_cleanup = :FooController
      Object.send :remove_const, klass_to_cleanup if Object.constants.include?(klass_to_cleanup)
    end

    it 'defines the controller class' do
      subject.build_controller :foo, actions: {
        index: {
          params: [:current_user, :params],
          context: 'foo_context_builder#bar',
          service: 'baz_service#qux'
        }
      }
      expect(Object.const_get("FooController")).not_to be_nil
    end

    it 'raises if there are no actions defined' do
      expect(->{subject.build_controller :foo, actions: {}}).to raise_exception
      expect(->{subject.build_controller :foop, {}}).to raise_exception
    end

    it 'raises if an action is missing context' do
      expect(->{subject.build_controller :foo, actions: {foo: {
        params: [:current_user, :params],
        service: 'baz_service#qux'
      }}}).to raise_exception
    end

    it 'raises if an action is missing service' do
      expect(->{subject.build_controller :foo, actions: {foo: {
        context: 'foo_context_builder#bar',
      }}}).to raise_exception
    end

    it 'adds the before actions' do
      class FooController
        def self.before_action(*args);end
      end

      expect(FooController).to receive(:before_action).with(:my_before_action)
      subject.build_controller :foo, 
        before_actions: [:my_before_action],
        actions: {
          index: {
            context: 'foo_context_builder#bar',
            service: 'baz_service#qux'
          }
        }

    end

    it 'sunny day get params, process, return object and status, render' do 
      class FooController
        def current_user; end
        def some_user; end
        def render(args); end
        def respond_to; end
      end
      controller = FooController.new

      expect(controller).to receive_messages(
        current_user: :some_user,
        params: {a: :b})

      render_args = nil
      expect(controller).to receive(:render) do |args|
        render_args = args
      end
      expect(controller).to receive(:respond_to) do |&block|
        block.call(json_format)
      end
      expect_any_instance_of(FooContextBuilder).to receive(:bar).with(hash_including(
        current_user: :some_user,
        params: {a: :b})) { :context }

      expect_any_instance_of(BazService).to receive(:qux).with(:context) do 
        { object: :some_obj, status: :ok }
      end

      subject.build_controller :foo, actions: {
        index: {
          params: [:current_user, :params],
          context: 'foo_context_builder#bar',
          service: 'baz_service#qux'
        }
      }
      controller.index

      expect(render_args).to eq(json: :some_obj, status: 200)
    end

    it 'renders error if service returns nil object' do
      class FooController
        def current_user; end
        def some_user; end
        def render(args); end
        def respond_to; end
      end

      subject.build_controller :foo, actions: {
        index: {
          params: [:current_user, :params],
          context: 'foo_context_builder#bar',
          service: 'baz_service#qux'
        }
      }
      controller = FooController.new
      expect(controller).to receive_messages(
        current_user: :some_user,
        params: {a: :b})

      render_args = nil
      expect(controller).to receive(:render) do |args|
        render_args = args
      end
      expect(controller).to receive(:respond_to) do |&block|
        block.call(json_format)
      end

      expect_any_instance_of(FooContextBuilder).to receive(:bar).with(hash_including(
        current_user: :some_user,
        params: {a: :b})) { :context }

      expect_any_instance_of(BazService).to receive(:qux).with(:context) do 
        { status: :error, errors: ["BOOM"] }
      end

      controller.index
      expect(render_args).to eq(json: {errors: ["BOOM"]}, status: 500)
    end

    it 'defines all the action methods' do
      class FooController
        def current_user; end
        def some_user; end
        def render(args); end
      end
      subject.build_controller :foo, 
        params: [:current_user, :params],
        actions: {
          index: {
            context: 'foo_context_builder#bar',
            service: 'baz_service#qux'
          },
          other: {
            context: 'foo_context_builder#bar',
            service: 'baz_service#qux'
          }
        }
      controller = FooController.new
      expect(controller).to respond_to(:index)
      expect(controller).to respond_to(:other)
    end

    class FooContextBuilder
      def bar(opts) {} end
    end

    class BazService
      def qux(context) {} end
    end
  end

end

