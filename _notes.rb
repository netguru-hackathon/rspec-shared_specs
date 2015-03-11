# This file contains shared specs used in many projects
# use as reference for good ideas

# https://github.com/netguru/openbooks/blob/2159a7933cc5a50c4630e1882afeaace5bdd9705/spec/support/api_shared_examples.rb


# https://gist.github.com/cintrzyk/922a11ce025f242391e1
# call sample
it_behaves_like 'resource forbidden with user', :destroy, :update do
  let(:other_user) { create(:user, account: account) }
  let(:resource) { 'YOUR_RESOURCE' }
end

# implementation
shared_examples 'resource forbidden with user' do |*actions|
  def build_path(name)
    path = "#{name}_path"
    path.prepend "#{namespace}_" if defined? namespace
    path.prepend 'api_'
  end

  let(:resource_name) { resource.class.name.underscore }
  let(:resource_path) { build_path resource_name }
  let(:resources_path) { build_path resource_name.pluralize }

  shared_examples 'on show' do
    before { api_get other_user, send(resource_path, resource) }
    it_behaves_like 'api request', 403
  end

  shared_examples 'on index' do
    before { api_get other_user, send(resources_path) }
    it_behaves_like 'api request', 403
  end

  shared_examples 'on create' do
    before { api_post(other_user, send(resources_path), {}) }
    it_behaves_like 'api request', 403
  end

  shared_examples 'on update' do
    before { api_put(other_user, send(resource_path, resource), {}) }
    it_behaves_like 'api request', 403
  end

  shared_examples 'on destroy' do
    before { api_delete other_user, send(resource_path, resource) }
    it_behaves_like 'api request', 403
  end

  (actions.any? ? actions : [:index, :show, :create, :update, :destroy]).each do |action|
    include_examples "on #{action}"
  end
end



# https://gist.github.com/cintrzyk/14d031b45089c077bee8
shared_examples 'invalid api response' do
  it_behaves_like 'api request', 409

  it 'contains errors key in response' do
    expect(JSON.parse(response.body).keys).to include 'errors'
  end
end

shared_examples 'JSON response with keys' do |keys|
  it 'has proper keys' do
    keys.each do |key|
      JSON.parse(response.body).keys.should include key
    end
  end
end

shared_examples 'array JSON response with keys' do |keys|
  it_behaves_like 'api array response'

  it 'has proper keys' do
    keys.each do |key|
      json_response.first.keys.should include key
    end
  end
end

shared_examples 'api array response' do |keys|
  it 'should return an array' do
    expect(json_response.class).to be Array
  end
end

shared_examples 'API request' do |status|
  it "has response status #{status ||= 200}" do
    expect(response.status).to eq status
  end

  it 'returns response with JSON Content-Type header' do
    expect(response.header['Content-Type']).to match Mime::JSON
  end
end

module APIControllerSupport
  def json_response
    @json_response ||= JSON.parse(response.body).with_indifferent_access
  end

  def obj_response
    @obj_response ||= Hashie::Mash.new json_response
  end
end



# https://github.com/edspencer/rspec-crud-controller-shared-example-groups/blob/master/crud_controller_matchers.rb

module CrudSetup
  def setup_crud_names
    # set up the variables we'll refer to in all specs below.
    # If we had an AssetsController, these would map to:
    # @model_name                    => 'Asset'
    # @model_klass                   => Asset
    # @model_symbol                  => :Asset
    # @pluralized_model_name         => 'Assets'
    # @assigns_model_name            => :asset
    # @pluralized_assigns_model_name => :assets
    @model_name                    = @model.classify
    @model_klass                   = @model_name.constantize
    @model_symbol                  = @model_name.to_sym
    @pluralized_model_name         = @model_name.humanize.pluralize
    @assigns_model_name            = @model_name.underscore.to_sym
    @pluralized_assigns_model_name = @model_name.underscore.pluralize.to_sym

    # continuing AssetsController example, this maps to:
    # @stubbed_model => mock_model(Asset, :id => 1)
    # @stubbed_model_collection => [@stubbed_model]
    # Asset.stub!(:find).and_return(@stubbed_model_collection)
    @stubbed_model = mock(@model_name, :id => 1, :to_xml => 'XML', :mock_object => true)
    @stubbed_model_collection = [@stubbed_model]
    @model_klass.stub!(:find).with(:all).and_return(@stubbed_model_collection)

    # e.g. Asset.stub!(:count).and_return(@count)
    @count = 10
    @model_klass.stub!(:count).and_return(@count)
  end
end

describe "CRUD GET index", :shared => true do
  include CrudSetup

  before(:each) do
    setup_crud_names
  end

  it "should find all #{@pluralized_model_name}" do
    @model_klass.should_receive(:find).with(:all)
    do_get
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should render the correct template" do
    do_get
    response.should render_template(:index)
  end

  it "should assign the #{@pluralized_model_name} to the #{@pluralized_model_name} view variable" do
    do_get
    assigns[@pluralized_assigns_model_name].should == @stubbed_model_collection
  end

  it "should render the correct xml" do
    @stubbed_model_collection.should_receive(:to_xml).and_return('XML')
    do_get nil, 'xml'
    response.body.should == 'XML'
  end

  def do_get page = nil, format = 'html'
    get 'index', :format => format
  end
end

describe "CRUD GET show", :shared => true do
  include CrudSetup

  before(:each) do
    setup_crud_names
  end

  describe "with a valid ID" do
    before(:each) do
      @model_klass.stub!(:find).and_return(@stubbed_model)
    end

    it "should find the correct #{@model_name}" do
      @model_klass.should_receive(:find).with(@stubbed_model.id.to_s).and_return(@stubbed_model)
      do_get
    end

    it "should render the correct template when requesting HTML" do
      do_get
      response.should render_template(:show)
    end

    it "should render the correct XML when requesting XML" do
      @stubbed_model.should_receive(:to_xml).and_return('XML')
      do_get 'xml'
      response.body.should == 'XML'
    end

    def do_get format = 'html'
      get 'show', :id => @stubbed_model.id, :format => format
    end
  end

  describe "with an invalid ID" do
    before(:each) do
      @model_klass.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
    end

    it "should redirect to /admin if not found via HTML" do
      do_get
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")
    end

    it "should send a 404 if not found via XML" do
      do_get 'xml'
      response.headers["Status"].should == "404 Not Found"
    end

    def do_get format = 'html'
      get 'show', :id => -1, :format => format
    end
  end
end

describe "CRUD POST create", :shared => true do
  include CrudSetup

  before(:each) do
    setup_crud_names
  end

  describe "with valid params" do

    before(:each) do
      @new_stubbed_model = mock_model(@model_klass, :id => 1, :save => true, :image? => false)
      @model_klass.stub!(:new).and_return(@new_stubbed_model)

      @params = {"title" => 'test', "key" => "value"}
    end

    it "should build a new #{@model_name}" do
      @model_klass.should_receive(:new).with(@params).and_return(@new_stubbed_model)
      do_post
    end

    it "should save the #{@model_name}" do
      @new_stubbed_model.should_receive(:save).and_return(true)
      do_post
    end

    it "should redirect to the new #{@model_name}'s show page when requesting HTML" do
      do_post
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}/#{@new_stubbed_model.id}/edit")
    end

    it "should return .to_xml when requesting XML" do
      @new_stubbed_model.should_receive(:to_xml).and_return('XML')
      do_post 'xml'
      response.body.should == "XML"
    end

    def do_post format = 'html'
      post 'create', @assigns_model_name => @params, :format => format
    end
  end

  describe "with invalid parameters" do
    before(:each) do
      @errors = mock_model(Array, :collect => [], :full_messages => [], :add => true, :to_xml => 'XML')

      @new_stubbed_model = mock_model(@model_klass, :id => 1, :save => true, :image? => false, :errors => @errors)
      @new_stubbed_model.stub!(:save).and_return(false)
      @model_klass.stub!(:new).and_return(@new_stubbed_model)

      @params = {"title" => 'test', "key" => "value"}
    end

    it "should render the new template when requesting HTML" do
      do_post
      response.should render_template(:new)
    end

    it "should render the errors to XML when requesting XML" do
      @errors.should_receive(:to_xml).and_return('XML')

      do_post 'xml'
      response.body.should == 'XML'
    end

    def do_post format = 'html'
      post 'create', @assigns_model_name => @params, :format => format
    end
  end
end

describe "CRUD PUT update", :shared => true do
  include CrudSetup

  before(:each) do
    setup_crud_names
  end

  describe "with valid parameters" do

    before(:each) do
      @stubbed_model.stub!(:update_attributes).and_return(true)

      @model_klass.stub!(:find).and_return(@stubbed_model)
    end

    it "should find the #{@model_name}" do
      @model_klass.should_receive(:find).with(@stubbed_model.id.to_s).and_return(@stubbed_model)
      do_put
    end

    it "should save the #{@model_name}" do
      @stubbed_model.should_receive(:update_attributes).with({"title" => 'test'}).and_return(true)
      do_put
    end

    it "should redirect to the index path when requesting HTML" do
      do_put
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")
      flash[:notice].should_not be(nil)
    end

    it "should render 200 OK for XML" do
      do_put 'xml'
      response.headers["Status"].should == "200 OK"
    end

    def do_put format = 'html'
      put 'update', :id => @stubbed_model.id, @assigns_model_name => {:title => 'test'}, :format => format
    end
  end

  describe "with invalid parameters" do
    before(:each) do
      @errors = mock_model(Array, :full_messages => [], :collect => [], :to_xml => 'XML')
      @stubbed_model.stub!(:errors).and_return(@errors)
      @stubbed_model.stub!(:update_attributes).and_return(false)

      @model_klass.stub!(:find).and_return(@stubbed_model)
    end

    it "should redirect to the #{@model_name} index if the #{@model_name} was not found" do
      @model_klass.should_receive(:find).and_raise(ActiveRecord::RecordNotFound)
      do_put

      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")
    end

    it "should render the edit action when requesting with HTML" do
      do_put
      response.should render_template(:edit)
    end

    it "should render the errors to XML when requesting with XML" do
      @errors.should_receive(:to_xml).and_return('XML')

      do_put 'xml'
      response.body.should == 'XML'
    end

    def do_put format = 'html'
      put 'update', :id => @stubbed_model.id, @assigns_model_name => {}, :format => format
    end
  end
end

describe "CRUD DELETE destroy", :shared => true do
  include CrudSetup

  before(:each) do
    setup_crud_names
  end

  describe "with a valid id" do

    before(:each) do
      @stubbed_model.stub!(:destroy).and_return(true)
      @model_klass.stub!(:find).and_return(@stubbed_model)
    end

    it "should find the correct #{@model_name}" do
      @model_klass.should_receive(:find).with(@stubbed_model.id.to_s).and_return(@stubbed_model)
      do_delete
    end

    it "should destroy the #{@model_name}" do
      @stubbed_model.should_receive(:destroy).and_return(true)
      do_delete
    end

    it "should redirect to #{@model_name} index when requesting HTML" do
      do_delete
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")
    end

    it "should render 200 when requesting XML" do
      do_delete 'xml'
      response.headers["Status"].should == "200 OK"
    end

    def do_delete format = 'html'
      delete 'destroy', :id => @stubbed_model.id, :format => format
    end
  end

  describe "with an invalid ID" do

    before(:each) do
      @model_klass.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
    end

    it "should redirect to #{@model_name} index when requesting HTML" do
      do_delete
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")
    end

    it "should render a 404 when requesting XML" do
      do_delete 'xml'
      response.headers["Status"].should == "404 Not Found"
    end

    def do_delete format = 'html'
      delete 'destroy', :id => -1, :format => format
    end
  end
end

describe "CRUD GET edit", :shared => true do
  include CrudSetup

  before(:each) do
    setup_crud_names
  end

  describe "with a valid ID" do
    before(:each) do
      @model_klass.stub!(:find).and_return(@stubbed_model)
    end

    it "should find the #{@model_name}" do
      @model_klass.should_receive(:find).with(@stubbed_model.id.to_s).and_return(@stubbed_model)
      do_get
    end

    it "should render the edit template when requesting HTML" do
      do_get
      response.should render_template(:edit)
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    def do_get format = 'html'
      get 'edit', :id => @stubbed_model.id, :format => format
    end
  end

  describe "with an invalid ID" do
    before(:each) do
      @model_klass.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
    end

    it "should redirect to the #{@model_name} index when requesting HTML" do
      do_get
      response.should redirect_to("/admin/#{@pluralized_assigns_model_name}")
    end

    it "should render a 404 when requesting XML" do
      do_get 'xml'
      response.headers["Status"].should == "404 Not Found"
    end

    def do_get format = 'html'
      get 'edit', :id => -1, :format => format
    end
  end
end




# https://github.com/svs/painless_controller_tests/blob/master/spec/controllers/items_controller_spec.rb

require 'spec_helper'

shared_examples "authorised index" do |user, items|
  describe "index" do
    before :each do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user
      get :index
    end
    it "should assign proper items" do
      assigns[:items].to_a.should =~ items
    end
    it "should respond ok" do
      response.should be_ok
    end
  end
end

shared_examples "authorised action" do
  before :each do
    action.call
  end

  it "should assign proper items" do
    if defined?(variable)
      variable.each do |k,v|
        assigns[k].should v.call
      end
    end
  end

  it "should satisfy expectations" do
    if defined?(expectations)
      expectations.each do |e|
        expect(action).to (e.call)
      end
    end
  end

  it "should render proper template/ redirect properly" do
    response.should redirect_to(redirect_url) if defined?(redirect_url)
    response.should render_template(template) if defined?(template)
  end

end


describe ItemsController do
  context "unauthorised" do
    before :all do
      @item = FactoryGirl.create(:item)
    end
    before :each do
      Ability.any_instance.stubs(:can?).returns(false)
    end

    it "does not index" do
      expect {get :index}.to raise_error CanCan::Unauthorized
    end
    it "does not new" do
      expect {get :new}.to raise_error CanCan::Unauthorized
    end
    it "does not show" do
      expect {get :show, {:id => @item.id}}.to raise_error CanCan::Unauthorized
    end
    it "does not edit" do
      expect {get :edit, {:id => @item.id}}.to raise_error CanCan::Unauthorized
    end
    it "does not update" do
      expect {put :update, {:id => @item.id, :item => {}}}.to raise_error CanCan::Unauthorized
    end
  end

  context "authorised" do
    describe "index" do
      Item.all.destroy!
      @u = FactoryGirl.create(:user)
      @admin = FactoryGirl.create(:admin)
      @tagger = FactoryGirl.create(:tagger)
      @i = FactoryGirl.create(:item, :user => @u)
      @i2 = FactoryGirl.create(:item, :taggable => true)

      it_behaves_like "authorised index", @u, [@i]
      it_behaves_like "authorised index", @admin, Item.all.to_a
      it_behaves_like "authorised index", @tagger, [@i2]
    end

    describe "other actions" do

      before :each do
        controller.stubs(:current_user => @user)
        Ability.any_instance.stubs(:can?).returns(true)
        @item = FactoryGirl.create(:item)
      end

      describe "new" do
        it_should_behave_like "authorised action" do
          let(:action) { Proc.new {post :new } }
          let(:variables) { {:item => Proc.new{be_a_new(Item)}} }
          let(:template) { :new }
        end
      end

      describe "show" do
        it_should_behave_like "authorised action" do
          let(:action) { Proc.new {post :show, {:id => @item.id} } }
          let(:variables) { {:item => lambda{ eq @item} } }
          let(:template) { :show }
        end
      end

      describe "edit" do
        it_should_behave_like "authorised action" do
          let(:action) { Proc.new {get :edit, {:id => @item.id} } }
          let(:variables) { {:item => lambda{ eq @item} } }
          let(:template) { :edit }
        end
      end

      describe "update" do
        before :each do
          Item.any_instance.expects(:save).returns(true)
        end
        it_should_behave_like "authorised action" do
          let(:action) { Proc.new {put :update, {:id => @item.id, :item => {}} } }
          let(:variables) { {:item => lambda{ eq @item} } }
          let(:redirect_url) { @item }
        end
      end

      describe "create" do
        it_should_behave_like "authorised action" do
          let(:action) { Proc.new {post :create, {:item => {:user_id => 1}} } }
          let(:variables) { {:item => lambda{ eq @item} } }
          let(:redirect_url) { assigns[:item] }
          let(:expectations) { [
                                lambda{ change(Item, :count).by(1)}
                               ]}

        end
      end
    end
  end
end


# https://github.com/netguru/devise-ios-rails-example/blob/master/spec/support/shared_examples/requests.rb

shared_examples "a good JSON request" do |response_code|
  it "returns an OK (#{response_code}) status code" do
    expect(subject.status).to eq(response_code)
  end

  it "is a JSON response" do
    expect(subject.content_type).to include 'application/json'
  end
end

shared_examples "a successful JSON GET request" do
  it_behaves_like "a good JSON request", 200
end

shared_examples "a successful JSON PUT request" do
  it_behaves_like "a good JSON request", 200
end

shared_examples "a successful JSON POST request" do
  it_behaves_like "a good JSON request", 201
end

shared_examples "a successful JSON DELETE request" do
  it_behaves_like "a good JSON request", 200
end

shared_examples "a bad JSON request" do |response_code|
  it "returns a (#{response_code}) status code" do
    expect(subject.status).to eq(response_code)
  end

  it "is a JSON response" do
    expect(subject.content_type).to include 'application/json'
  end

  it "returns an error object" do
    expect(json_for(subject)).to have_key('error')
  end
end

shared_examples "an unsuccessful JSON request" do
  it_behaves_like "a bad JSON request", 400
end

shared_examples "an unauthorized JSON request" do
  it_behaves_like "a bad JSON request", 401

  it "returns error object" do
    json_response = json_for(subject)
    expect(json_response).to have_key('error')
  end
end

shared_examples "a forbidden JSON request" do
  it_behaves_like "a bad JSON request", 403

  it "returns error object" do
    json_response = json_for(subject)
    expect(json_response).to have_key('error')
  end
end

shared_examples "a not found JSON request" do
  it_behaves_like "a bad JSON request", 404
end



# https://github.com/netguru/devise-ios-rails-example/blob/master/spec/support/shared_examples/authorized.rb

shared_examples "needs authorization" do
  context "without authentication" do
    before do
      current_session.header('X-User-Token', nil)
      current_session.header('X-User-Email', nil)
    end

    it_behaves_like "an unauthorized JSON request"
  end

  context "with invalid authentication" do
    before { build(:authentication, user: user).set_headers(current_session) }

    let(:user) { build(:user) }

    it_behaves_like "an unauthorized JSON request"
  end
end
