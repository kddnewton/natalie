require_relative '../../spec_helper'
require_relative 'fixtures/source_location'

describe "Proc#source_location" do
  before :each do
    @proc = ProcSpecs::SourceLocation.my_proc
    @lambda = ProcSpecs::SourceLocation.my_lambda
    @proc_new = ProcSpecs::SourceLocation.my_proc_new
    @method = ProcSpecs::SourceLocation.my_method
  end

  it "returns an Array" do
    @proc.source_location.should be_an_instance_of(Array)
    @proc_new.source_location.should be_an_instance_of(Array)
    @lambda.source_location.should be_an_instance_of(Array)
    @method.source_location.should be_an_instance_of(Array)
  end

  it "sets the first value to the path of the file in which the proc was defined" do
    file = @proc.source_location.first
    file.should be_an_instance_of(String)
    file.should == File.realpath('fixtures/source_location.rb', __dir__)

    file = @proc_new.source_location.first
    file.should be_an_instance_of(String)
    file.should == File.realpath('fixtures/source_location.rb', __dir__)

    file = @lambda.source_location.first
    file.should be_an_instance_of(String)
    NATFIXME 'It currently uses a relative path for lambda', exception: SpecFailedException do
      file.should == File.realpath('fixtures/source_location.rb', __dir__)
    end

    file = @method.source_location.first
    file.should be_an_instance_of(String)
    file.should == File.realpath('fixtures/source_location.rb', __dir__)
  end

  it "sets the last value to an Integer representing the line on which the proc was defined" do
    line = @proc.source_location.last
    line.should be_an_instance_of(Integer)
    line.should == 4

    line = @proc_new.source_location.last
    line.should be_an_instance_of(Integer)
    line.should == 12

    line = @lambda.source_location.last
    line.should be_an_instance_of(Integer)
    NATFIXME 'Fix line in Env', exception: SpecFailedException do
      line.should == 8
    end

    line = @method.source_location.last
    line.should be_an_instance_of(Integer)
    NATFIXME 'Fix line in Env', exception: SpecFailedException do
      line.should == 15
    end
  end

  it "works even if the proc was created on the same line" do
    proc { true }.source_location.should == [__FILE__, __LINE__]
    Proc.new { true }.source_location.should == [__FILE__, __LINE__]
    NATFIXME 'Fix line in Env', exception: SpecFailedException do
      -> { true }.source_location.should == [__FILE__, __LINE__]
    end
  end

  it "returns the first line of a multi-line proc (i.e. the line containing 'proc do')" do
    ProcSpecs::SourceLocation.my_multiline_proc.source_location.last.should == 20
    ProcSpecs::SourceLocation.my_multiline_proc_new.source_location.last.should == 34
    NATFIXME "returns the first line of a multi-line proc (i.e. the line containing 'proc do'", exception: SpecFailedException do
      ProcSpecs::SourceLocation.my_multiline_lambda.source_location.last.should == 27
    end
  end

  it "returns the location of the proc's body; not necessarily the proc itself" do
    ProcSpecs::SourceLocation.my_detached_proc.source_location.last.should == 41
    ProcSpecs::SourceLocation.my_detached_proc_new.source_location.last.should == 51
    NATFIXME 'Why does this call IO#source_location', exception: NoMethodError, message: /undefined method `source_location' for #<[^>]+>:IO/ do
      ProcSpecs::SourceLocation.my_detached_lambda.source_location.last.should == 46
    end
  end

  it "returns the same value for a proc-ified method as the method reports" do
    method = ProcSpecs::SourceLocation.method(:my_proc)
    proc = method.to_proc

    NATFIXME 'Implement Method#source_location', exception: NoMethodError, message: /undefined method `source_location' for .*:Method/ do
      method.source_location.should == proc.source_location
    end
  end

  it "returns nil for a core method that has been proc-ified" do
    method = [].method(:<<)
    proc = method.to_proc

    NATFIXME 'returns nil for a core method that has been proc-ified', exception: SpecFailedException do
      proc.source_location.should == nil
    end
  end

  it "works for eval with a given line" do
    proc = eval('-> {}', nil, "foo", 100)
    NATFIXME 'Support eval', exception: SpecFailedException do
      proc.source_location.should == ["foo", 100]
    end
  end
end
