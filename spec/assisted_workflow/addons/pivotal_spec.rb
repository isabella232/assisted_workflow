require 'spec_helper'
require 'assisted_workflow/addons/pivotal'

describe AssistedWorkflow::Addons::Pivotal do

  before do
    @configuration = {
      "token" => "mypivotaltoken",
      "project_id" => "1",
      "username" => "flavio",
      "fullname" => "Flavio Granero"
    }
    # stubs
    @client = TrackerApi::Client.new(token: "mypivotaltoken")
    stub(TrackerApi::Client).new{ @client }
    @project = TrackerApi::Resources::Project.new(client: @client, id: 1)
    stub(@client).project(@configuration["project_id"]){ @project }
    stub(@client).me{ TrackerApi::Resources::Me.new }

    @pivotal = AssistedWorkflow::Addons::Pivotal.new(nil, @configuration)
  end

  it "initializes a valid pivotal addon" do
    assert @pivotal.valid?
  end

  it "requires fullname" do
    proc {
      AssistedWorkflow::Addons::Pivotal.new(
        nil,
        @configuration.reject{|k,v| k == "fullname"}
      )
    }.must_raise AssistedWorkflow::Error, "pivotal missing configuration:[fullname]"
  end

  it "requires token" do
    proc {
      AssistedWorkflow::Addons::Pivotal.new(
        nil,
        @configuration.reject{|k,v| k == "token"}
      )
    }.must_raise AssistedWorkflow::Error, "pivotal missing configuration:[token]"
  end

  it "requires project_id" do
    proc {
      AssistedWorkflow::Addons::Pivotal.new(
        nil,
        @configuration.reject{|k,v| k == "project_id"}
      )
    }.must_raise AssistedWorkflow::Error, "pivotal missing configuration:[project_id]"
  end

  it "finds a story by id" do
    mock(@project).story("100001") do |story_id|
      story_stub(:id => story_id, :project_id => @project.id)
    end

    story = @pivotal.find_story("100001")
    story.id.must_equal 100001
  end

  it "returns pending stories" do
    stub(@project).stories do
      [
        story_stub(:id => "100001", :project_id => @project.id),
        story_stub(:id => "100002", :project_id => @project.id)
      ]
    end

    stories = @pivotal.pending_stories(:include_started => true)
    stories.size.must_equal 2
  end

  it "starts a story" do
    story = story_stub(:id => "100001", :project_id => @project.id)
    @pivotal.start_story(story, :estimate => "3")
    story.current_state.must_match(/started/)
    story.estimate.must_equal 3
  end

  it "finishes a story" do
    story = story_stub(:id => "100001", :project_id => @project.id)
    #stub post to create comment
    url = "/projects/#{story.project_id}/stories/#{story.id}/comments"
    stub(@client).post(url, :params => {:text=>"pull_request_url"}){}

    @pivotal.finish_story(story, :note => "pull_request_url")
    story.current_state.must_match(/finished/)
  end

  private #===================================================================

  def story_stub(attributes = {})
    any_instance_of(TrackerApi::Resources::Story) do |klass|
      stub(klass).comments { [] }
      stub(klass).tasks { [] }
    end
    story = TrackerApi::Resources::Story.new(attributes.merge(client: @client))
    stub(story).save {}

    story
  end
end
