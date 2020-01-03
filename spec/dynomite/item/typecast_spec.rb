describe Dynomite::Item::Typecaster do
  let(:caster) { Dynomite::Item::Typecaster.new(model) }
  let(:model)  { double(:model).as_null_object }

  context "dump" do
    it "string" do
      result = caster.dump("string")
      expect(result).to eq "string"
    end

    it "array" do
      result = caster.dump(["a","b"])
      expect(result).to eq ["a","b"]
    end

    it "hash" do
      result = caster.dump(a: 1, b: 2)
      expect(result).to eq(a: 1, b: 2)
    end

    it "datetime" do
      s = "2020-01-09T17:28:39Z"
      time = Time.parse(s)
      result = caster.dump(time)
      expect(result).to eq s
    end
  end

  context "load" do
    it "string" do
      result = caster.load("string")
      expect(result).to eq "string"
    end

    it "array" do
      result = caster.load(["a","b"])
      expect(result).to eq ["a","b"]
    end

    it "hash" do
      result = caster.load(a: 1, b: 2)
      expect(result).to eq(a: 1, b: 2)
    end

    it "datetime" do
      s = "2020-01-09T17:28:39Z"
      result = caster.load(s)
      time = Time.parse(s)
      expect(result).to eq time
    end
  end
end
