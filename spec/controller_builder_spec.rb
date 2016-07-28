require 'spec_helper'

describe DDC::ControllerBuilder do
  subject { described_class }

  describe '.build' do
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
      subject.build :foo, actions: {
        index: {
          context_params: [:current_user, :params],
          context: 'foo_context_builder#bar',
          service: 'baz_service#qux'
        }
      }
      expect(Object.const_get("FooController")).not_to be_nil
    end

    it 'raises if there are no actions defined' do
      expect(->{subject.build :foo, actions: {}}).to raise_exception
      expect(->{subject.build :foop, {}}).to raise_exception
    end

    it 'raises if an action is missing context' do
      expect(->{subject.build :foo, actions: {foo: {
        context_params: [:current_user, :params],
        service: 'baz_service#qux'
      }}}).to raise_exception
    end

    it 'raises if an action is missing service' do
      expect(->{subject.build :foo, actions: {foo: {
        context: 'foo_context_builder#bar',
      }}}).to raise_exception
    end

    it 'uses the provided parent class' do
      class DarthVader
      end

      klass = subject.build :foo,
        parent: DarthVader,
        actions: {
          index: {
            context: 'foo_context_builder#bar',
            service: 'baz_service#qux'
          }
        }
      expect(klass.ancestors[1]).to be(DarthVader)
    end

    it 'adds the before actions' do
      class FooController
        def self.before_action(*args);end
      end

      expect(FooController).to receive(:before_action).with(:my_before_action)
      subject.build :foo,
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

      subject.build :foo, actions: {
        index: {
          context_params: [:current_user, :params],
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

      subject.build :foo, actions: {
        index: {
          context_params: [:current_user, :params],
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
      subject.build :foo,
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

    context 'render_opts' do

      let (:controller) {
        class FooController
          def current_user; end
          def some_user; end
          def render(args); end
          def respond_to; end
        end
        FooController.new
      }
      before do
        expect(controller).to receive_messages( params: {a: :b})

        subject.build :foo,
          actions: {
            index: {
              context: 'foo_context_builder#bar',
              service: 'baz_service#qux',
              render_opts: {
                serializer: MySerializer
              }
            },
            show: {
              context: 'foo_context_builder#bar',
              service: 'baz_service#qux',
              render_opts: {
                serializer: MySerializer
              },
              object_render_opts: {
                serializer: MyObjectSerializer
              },
              error_render_opts: {
                serializer: MyErrorSerializer
              },
            }

          }

        @render_args = nil
        expect(controller).to receive(:render) do |args|
          @render_args = args
        end
        expect(controller).to receive(:respond_to) do |&block|
          block.call(json_format)
        end
        expect_any_instance_of(FooContextBuilder).to receive(:bar).with(hash_including(
          params: {a: :b})) { :context }
      end

      it 'uses specified serializer json render calls' do
        expect_any_instance_of(BazService).to receive(:qux).with(:context) do
          { object: :some_obj, status: :ok }
        end
        controller.index
        expect(@render_args[:serializer]).to eq(MySerializer)
      end

      it 'uses object_render_opts' do
        expect_any_instance_of(BazService).to receive(:qux).with(:context) do
          { object: :some_obj, status: :ok }
        end
        controller.show
        expect(@render_args[:serializer]).to eq(MyObjectSerializer)
      end

      it 'uses error_render_opts' do
        expect_any_instance_of(BazService).to receive(:qux).with(:context) do
          { errors: [], status: :not_valid }
        end
        controller.show
        expect(@render_args[:serializer]).to eq(MyErrorSerializer)
      end
    end

    class MySerializer
    end

    class MyObjectSerializer
    end

    class MyErrorSerializer
    end

    class FooContextBuilder
      def bar(opts) {} end
    end

    class BazService
      def qux(context) {} end
    end

    class MultiContextBuilder
      def foo(opts) {foo: 2} end
      def bar(opts) {bar: 3} end
    end

    class MultiContextService
      def check(ctx)
        {status: :ok, object: ctx[:foo] + ctx[:bar]}
      end
    end

    it 'supports multiple contexts' do
      class FooController
        def render(args); end
        def respond_to; end
      end
      subject.build :foo, actions: {
        index: {
          context_params: [],
          contexts: ['multi_context_builder#foo', 'multi_context_builder#bar'],
          service: 'multi_context_service#check'
        }
      }
      expect(Object.const_get("FooController")).not_to be_nil
      controller = Object.const_get("FooController").new
      render_args = nil
      expect(controller).to receive(:render) do |args|
        render_args = args
      end
      expect(controller).to receive(:respond_to) do |&block|
        block.call(json_format)
      end
      controller.index
      expect(render_args[:json]).to eq(5)
    end
  end
end

