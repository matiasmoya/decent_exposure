require "spec_helper"

describe AdequateExposure::Controller do
  class Thing; end
  class DifferentThing; end

  class BaseController
    def self.helper_method(*); end

    def params
      @params ||= HashWithIndifferentAccess.new
    end
  end

  let(:controller_klass) do
    Class.new(BaseController) do
      extend AdequateExposure::Controller
    end
  end

  let(:controller){ controller_klass.new }

  def expose(*args, &block)
    controller_klass.expose(*args, &block)
  end

  context "getter/setter methods" do
    before{ expose :thing }

    it "defines getter method" do
      expect(controller).to respond_to(:thing)
    end

    it "defines setter method" do
      expect(controller).to respond_to(:thing=).with(1).argument
    end
  end

  context "helper methods" do
    it "exposes getter and setter as controller helper methods" do
      expect(controller_klass).to receive(:helper_method).with(:thing, :thing=)
      expose :thing
    end
  end

  context "with block" do
    before do
      expose(:thing){ compute_thing }
    end

    it "executes block to calculate the value" do
      allow(controller).to receive(:compute_thing).and_return(42)
      expect(controller.thing).to eq(42)
    end

    it "executes the block once and memoizes the result" do
      expect(controller).to receive(:compute_thing).once.and_return(42)
      10.times{ controller.thing }
    end

    it "allows setting value directly" do
      expect(controller).to_not receive(:compute_thing)
      controller.thing = :foobar
      expect(controller.thing).to eq(:foobar)
    end
  end

  context "redefine fetch" do
    before do
      expose :thing, fetch: ->{ compute_thing }
      allow(controller).to receive(:compute_thing).and_return(42)
    end

    it "uses provided fetch proc instead of default" do
      expect(controller.thing).to eq(42)
    end
  end

  context "default behaviour" do
    before{ expose :thing }

    it "builds a new instance when id is not provided" do
      expect(controller.thing).to be_instance_of(Thing)
    end

    context "find" do
      before{ expect(Thing).to receive(:find).with(10) }
      after{ controller.thing }

      it "finds Thing if thing_id param is provided" do
        controller.params.merge! thing_id: 10
      end

      it "finds Thing if id param if provided" do
        controller.params.merge! id: 10
      end
    end
  end

  context "override model" do
    after{ expect(controller.thing).to be_instance_of(DifferentThing) }

    it "allows overriding model class with proc" do
      expose :thing, model: ->{ DifferentThing }
    end

    it "allows overriding model with class" do
      expose :thing, model: DifferentThing
    end

    it "allows overriding model class with symbol" do
      expose :thing, model: :different_thing
    end
  end

  context "override scope" do
    it "allows overriding scope with proc" do
      scope = double("Scope")
      expose :thing, scope: ->{ scope }
      expect(scope).to receive(:new).and_return(42)
      expect(controller.thing).to eq(42)
    end

    it "allows overriding with symbol" do
      current_user = double("User")
      scope = double("Scope")
      scoped_thing = double("Thing")

      expect(controller).to receive(:current_user).and_return(current_user)
      expect(current_user).to receive(:things).and_return(scope)
      expect(scope).to receive(:new).and_return(scoped_thing)
      expose :thing, scope: :current_user

      expect(controller.thing).to eq(scoped_thing)
    end
  end

  context "override id" do
    after do
      expect(Thing).to receive(:find).with(42)
      controller.thing
    end

    it "allows overriding id with proc" do
      expose :thing, id: ->{ get_thing_id_somehow }
      expect(controller).to receive(:get_thing_id_somehow).and_return(42)
    end

    it "allows overriding id with symbol" do
      expose :thing, id: :custom_thing_id
      controller.params.merge! thing_id: 10, custom_thing_id: 42
    end

    it "allows overriding id with an array of symbols" do
      expose :thing, id: %i[non-existent-id lolwut another_id_param]
      controller.params.merge! another_id_param: 42
    end
  end

  context "override decorator" do
    it "allows specify decorator" do
      expose :thing, decorate: ->(thing){ decorate(thing) }
      expect(controller).to receive(:decorate).with(an_instance_of(Thing))
      controller.thing
    end
  end
end