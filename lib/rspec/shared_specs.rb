require "rspec/shared_specs/version"

module Rspec
  module SharedSpecs
    # if val is callable, then it's result is return; otherwise val is returned
    def __result(val, *args)
      val.kind_of?(Proc) ? val.call(*args) : val
    end

    # the idea is to have default config for all specs; this config should be overridable
    # per project and then for each case
    CONFIG = {
      template: ->(controller) { controller.action_name },
      authentication: {
        fail_status: 401,
        json: { "error" => "You need to sign in or sign up before continuing." },
      },
      authorization: {
        fail_status: 403,
      },
      create: {
        success_status: 201,
        fail_status: 422,
      },
      update: {
        success_status: 200,
        fail_status: 422,
      },
      destroy: {
        success_status: 200,
      },
    }

    shared_context 'merge config' do
      let(:__local_config) do
        global_config = Rspec::SharedSpecs::CONFIG
        defined?(case_config) ? global_config.merge(case_config) : global_config.dup
      end
    end

    shared_context 'authenticated' do
      before do
        authenticate_user(current_user)
      end
    end

    shared_context 'format: html' do
      before do
        params['format'] = 'html'
      end
    end

    shared_context 'format: json' do
      before do
        params['format'] = 'json'
      end
    end

    shared_examples_for 'HTML action requiring login' do
      context 'when user is not logged in' do
        it 'redirects to root if user is not logged in' do
          expect(subject).to redirect_to(new_user_session_path)
        end
      end
    end

    shared_examples_for 'JSON action requiring login' do
      context 'when user is not logged in' do
        let(:expected_json) { Rspec::SharedSpecs::CONFIG[:authentication][:json] }
        it_behaves_like 'action rendering json',
          Rspec::SharedSpecs::CONFIG[:authentication][:fail_status]
      end
    end

    shared_examples_for 'action ending with status' do |status|
      it "answers with #{status} status" do
        expect(subject.status).to eq(status)
      end
    end

    shared_examples_for 'action rendering json' do |status|
      status ||= 200
      it_behaves_like 'action ending with status', status

      it 'renders proper json' do
        parsed_json = JSON.parse(subject.body)
        expect(parsed_json).to eq(expected_json)
      end
    end

    shared_examples_for 'action rendering template' do
      include_context 'merge config'
      render_views

      it 'renders template' do
        template_name = __result(__local_config[:template], controller)
        expect(subject).to render_template(template_name)
      end
    end

    shared_examples_for 'GET index JSON' do
      include_context 'merge config'
      include_context 'format: json'

      it_behaves_like 'JSON action requiring login'

      context 'when user is logged in' do
        include_context 'authenticated'

        it_behaves_like 'action rendering json'
      end
    end

    # TODO:
    # add CRUD specs for JSON and HTML
  end
end
