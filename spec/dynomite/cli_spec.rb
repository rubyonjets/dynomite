describe Dynomite::CLI do
  describe "dynomite" do
    it "generate" do
      out = execute("NOOP=1 exe/dynomite generate create_users")
      expect(out).to include("Generating migration")
    end
  end
end
