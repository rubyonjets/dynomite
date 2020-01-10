class CallbacksTester < Dynomite::Item
  field :title

  before_initialize :initialize_hook
  before_create :create_hook
  before_save :save_hook
  before_update :update_hook
  before_destroy :destroy_hook

  def initialize_hook
    @initialize_hook = true
  end

  def create_hook
    @create_hook = true
  end

  def save_hook
    @save_hook = true
  end

  def update_hook
    @update_hook = true
  end

  def destroy_hook
    @destroy_hook = true
  end
end

describe Dynomite::Item do
  let(:model_klass) do
    klass = CallbacksTester
    allow(klass.db).to receive(:put_item).and_return(null)
    klass
  end
  let(:null) { double(:null).as_null_object }

  it "initialize" do
    model = model_klass.new

    expect(model.instance_variable_get(:@initialize_hook)).to be true
    expect(model.instance_variable_get(:@create_hook)).to be nil
    expect(model.instance_variable_get(:@save_hook)).to be nil
    expect(model.instance_variable_get(:@update_hook)).to be nil
    expect(model.instance_variable_get(:@destroy_hook)).to be nil
  end

  it "create class method" do
    model = model_klass.create

    expect(model.instance_variable_get(:@initialize_hook)).to be true
    expect(model.instance_variable_get(:@create_hook)).to be true
    expect(model.instance_variable_get(:@save_hook)).to be true
    expect(model.instance_variable_get(:@update_hook)).to be nil
    expect(model.instance_variable_get(:@destroy_hook)).to be nil
  end

  it "save" do
    model = model_klass.new

    expect(model.instance_variable_get(:@save_hook)).to be nil
    expect(model.instance_variable_get(:@create_hook)).to be nil

    model.save

    expect(model.instance_variable_get(:@initialize_hook)).to be true
    expect(model.instance_variable_get(:@create_hook)).to be true
    expect(model.instance_variable_get(:@save_hook)).to be true
    expect(model.instance_variable_get(:@update_hook)).to be nil
    expect(model.instance_variable_get(:@destroy_hook)).to be nil
  end

  it "update" do
    model = model_klass.new

    expect(model.instance_variable_get(:@save_hook)).to be nil
    expect(model.instance_variable_get(:@create_hook)).to be nil
    expect(model.instance_variable_get(:@update_hook)).to be nil

    model.update(title: "test")

    expect(model.instance_variable_get(:@initialize_hook)).to be true
    expect(model.instance_variable_get(:@create_hook)).to be nil
    expect(model.instance_variable_get(:@save_hook)).to be true
    expect(model.instance_variable_get(:@update_hook)).to be true
    expect(model.instance_variable_get(:@destroy_hook)).to be nil
  end

  it "destroy" do
    model = model_klass.new
    expect(model_klass.db).to receive(:delete_item)

    expect(model.instance_variable_get(:@destroy_hook)).to be nil

    model.destroy

    expect(model.instance_variable_get(:@initialize_hook)).to be true
    expect(model.instance_variable_get(:@create_hook)).to be nil
    expect(model.instance_variable_get(:@save_hook)).to be nil
    expect(model.instance_variable_get(:@update_hook)).to be nil
    expect(model.instance_variable_get(:@destroy_hook)).to be true
  end
end
