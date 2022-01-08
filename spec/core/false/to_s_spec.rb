require_relative '../../spec_helper'

describe "FalseClass#to_s" do
  it "returns the string 'false'" do
    false.to_s.should == "false"
  end

  ruby_version_is "2.7" do
    it "returns a frozen string" do
      false.to_s.should.frozen?
    end

    # NATFIXME: FalseClass#to_s should always return the same string
    xit "always returns the same string" do
      false.to_s.should equal(false.to_s)
    end
  end
end
