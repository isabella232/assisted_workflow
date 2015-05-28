require "assisted_workflow/exceptions"
require "assisted_workflow/addons/base"
require "tracker_api"

# wrapper class to pivotal api client
module AssistedWorkflow::Addons

  class PivotalStory < SimpleDelegator
    def initialize(story)
      super
    end

    def owners_str
      url = "/projects/#{project_id}/stories/#{id}/owners"
      client.get(url).body.map{|owner| owner["name"]}.join(", ")
    end
  end

  class Pivotal < Base
    required_options :fullname, :token, :project_id
  
    def initialize(output, options = {})
      super

      @client = TrackerApi::Client.new(token: options["token"])
      begin
        @project = @client.project(options["project_id"])
      rescue
        raise AssistedWorkflow::Error, "pivotal project #{options["project_id"]} not found."
      end
      @fullname = options["fullname"]
      @username = options["username"]
    end
  
    def find_story(story_id)
      if story_id.to_i > 0
        log "loading story ##{story_id}"
        PivotalStory.new(@project.story(story_id))
      end
    end
  
    def start_story(story, options = {})
      log "starting story ##{story.id}"
      options.delete(:estimate) if options[:estimate].nil?
      update_story!(story, options.merge(:current_state => "started"))
    end

    def finish_story(story, options = {})
      log "finishing story ##{story.id}"
      saved = update_story! story, :current_state => finished_state(story)
      if saved && options[:note]
        add_comment_to_story(story, options[:note])
      end
    end
  
    def pending_stories(options = {})
      log "loading pending stories"
      states = ["unstarted"]
      states << "started" if options[:include_started]
      filter_str = "state:#{states.join(',')} owned_by:#{@client.me.id}"
      stories = @project.stories(:filter => filter_str, :limit => 5)
      stories.map do |story|
        PivotalStory.new(story)
      end
    end
    
    def valid?
      !@project.nil?
    end

    private

    def add_comment_to_story(story, text)
      url = "/projects/#{story.project_id}/stories/#{story.id}/comments"
      @client.post(url, params: {:text => text})
    rescue TrackerApi::Error => e
      body = e.response[:body]
      msg = body["possible_fix"] || body["general_problem"]
      raise AssistedWorkflow::Error, msg
    end
  
    def finished_state(story)
      if story.story_type == "chore"
        "accepted"
      else
        "finished"
      end
    end
    
    def update_story!(story, attributes)
      if story
        begin
          story.attributes = attributes
          story.save
        rescue TrackerApi::Error => e
          body = e.response[:body]
          msg = body["possible_fix"] || body["general_problem"]
          raise AssistedWorkflow::Error, msg
        end
        true
      end
    end
  end
end
