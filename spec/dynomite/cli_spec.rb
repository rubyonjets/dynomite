describe Dynomite::CLI do
  describe "dynomite" do
    it "hello" do
      out = execute("NOOP=1 exe/dynomite generate create_users")
      expect(out).to include("from: Tung\nHello world")
    end
  end
end
