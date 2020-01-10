class MagicFieldsTester < Dynomite::Item
end

describe Dynomite::Item do
  it "magic fields" do
    expect(MagicFieldsTester.db).to receive(:put_item)
    model = MagicFieldsTester.new

    expect(model.id).to be nil
    expect(model.created_at).to be nil
    expect(model.updated_at).to be nil
    expect(model.new_record?).to be true

    model.save

    expect(model.id).not_to be nil
    expect(model.created_at).not_to be nil
    expect(model.updated_at).not_to be nil
    expect(model.new_record?).to be false
  end
end
