---
title: Site Controller Overview
---
# Introduction

This document will walk you through the implementation of the <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="8:3:3" line-data="  class EventsController &lt; Calagator::ApplicationController">`EventsController`</SwmToken> in the Calagator application.

The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="8:3:3" line-data="  class EventsController &lt; Calagator::ApplicationController">`EventsController`</SwmToken> handles various actions related to event management, including creating, updating, deleting, and displaying events. It also includes functionality for handling duplicates and locked events.

We will cover:

1. High-level explanation of the code's purpose.
2. Breakdown of the methods.
3. Dependencies.

# High-level explanation of the code's purpose

The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="8:3:3" line-data="  class EventsController &lt; Calagator::ApplicationController">`EventsController`</SwmToken> is responsible for managing event-related actions in the Calagator application. It includes methods for CRUD operations, handling duplicates, and managing event locks. The controller ensures that events are properly validated, saved, and rendered in various formats.

# Dependencies

<SwmSnippet path="/app/controllers/calagator/events_controller.rb" line="1">

---

The controller relies on several dependencies to function correctly:

- <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="3:3:5" line-data="require &#39;recaptcha/rails&#39;">`recaptcha/rails`</SwmToken>: Used for verifying <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="3:3:3" line-data="require &#39;recaptcha/rails&#39;">`recaptcha`</SwmToken> responses.
- <SwmPath>[lib/calagator/duplicate_checking/](/lib/calagator/duplicate_checking/)</SwmPath>: Provides functionality for checking and handling duplicate events.
- <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="5:3:7" line-data="require &#39;calagator/duplicate_checking/controller_actions&#39;">`calagator/duplicate_checking/controller_actions`</SwmToken>: Includes controller actions for duplicate checking.

```
# frozen_string_literal: true

require 'recaptcha/rails'
require 'calagator/duplicate_checking'
require 'calagator/duplicate_checking/controller_actions'

module Calagator
  class EventsController < Calagator::ApplicationController
    # Provides #duplicates and #squash_many_duplicates
    include Calagator::DuplicateChecking::ControllerActions
    require_admin only: %i[duplicates squash_many_duplicates]
```

---

</SwmSnippet>

# Breakdown of the methods

## Index method

<SwmSnippet path="/app/controllers/calagator/events_controller.rb" line="12">

---

The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="17:3:3" line-data="    def index">`index`</SwmToken> method retrieves and displays a list of events. It uses the <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="18:6:8" line-data="      @browse = Event::Browse.new(params)">`Event::Browse`</SwmToken> class to fetch events based on the provided parameters and handles any errors by appending them to the flash messages.

```

    before_action :find_and_redirect_if_locked, only: %i[edit update destroy]

    # GET /events
    # GET /events.xml
    def index
      @browse = Event::Browse.new(params)
      @events = @browse.events
      @browse.errors.each { |error| append_flash :failure, error }
      render_events @events
    end
```

---

</SwmSnippet>

## Show method

<SwmSnippet path="/app/controllers/calagator/events_controller.rb" line="23">

---

The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="26:3:3" line-data="    def show">`show`</SwmToken> method displays a specific event. If the event is marked as a duplicate, it redirects to the originator event. If the event is not found, it redirects to the events index with an error message.

```

    # GET /events/1
    # GET /events/1.xml
    def show
      @event = Event.find(params[:id])
      return redirect_to(@event.originator) if @event.duplicate?

      render_event @event
    rescue ActiveRecord::RecordNotFound => e
      redirect_to events_path, flash: { failure: e.to_s }
    end
```

---

</SwmSnippet>

## New and edit methods

<SwmSnippet path="/app/controllers/calagator/events_controller.rb" line="34">

---

The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="35:8:8" line-data="    # GET /events/new">`new`</SwmToken> method initializes a new event object with permitted parameters. The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="41:10:10" line-data="    # GET /events/1/edit">`edit`</SwmToken> method is a placeholder for editing an existing event.

```

    # GET /events/new
    # GET /events/new.xml
    def new
      @event = Event.new(params.permit![:event])
    end

    # GET /events/1/edit
    def edit; end
```

---

</SwmSnippet>

## Create and update methods

<SwmSnippet path="/app/controllers/calagator/events_controller.rb" line="43">

---

The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="46:3:3" line-data="    def create">`create`</SwmToken> and <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="53:3:3" line-data="    def update">`update`</SwmToken> methods both use the <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="48:1:1" line-data="      create_or_update">`create_or_update`</SwmToken> method to handle the saving of events. This method uses the <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="58:5:7" line-data="      saver = Event::Saver.new(@event, params.permit!)">`Event::Saver`</SwmToken> class to save the event and verifies <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="3:3:3" line-data="require &#39;recaptcha/rails&#39;">`recaptcha`</SwmToken> responses. It also handles different response formats and redirects based on the success or failure of the save operation.

```

    # POST /events
    # POST /events.xml
    def create
      @event = Event.new
      create_or_update
    end

    # PUT /events/1
    # PUT /events/1.xml
    def update
      create_or_update
    end

    def create_or_update
      saver = Event::Saver.new(@event, params.permit!)
      respond_to do |format|
        if recaptcha_verified?(@event) && saver.save
          format.html do
            flash[:success] = 'Event was successfully saved.'
            if saver.has_new_venue?
              flash[:success] += " Please tell us more about where it's being held."
              redirect_to edit_venue_url(@event.venue, from_event: @event.id)
            else
              redirect_to @event
            end
          end
          format.xml  { render xml: @event, status: :created, location: @event }
        else
          format.html do
            flash[:failure] = saver.failure
            render action: @event.new_record? ? 'new' : 'edit'
          end
          format.xml { render xml: @event.errors, status: :unprocessable_entity }
        end
      end
    end
```

---

</SwmSnippet>

## Destroy method

<SwmSnippet path="/app/controllers/calagator/events_controller.rb" line="80">

---

The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="83:3:3" line-data="    def destroy">`destroy`</SwmToken> method deletes an event and redirects to the events index with a success message. It also handles different response formats.

```

    # DELETE /events/1
    # DELETE /events/1.xml
    def destroy
      @event.destroy

      respond_to do |format|
        format.html { redirect_to(events_url, flash: { success: "\"#{@event.title}\" has been deleted" }) }
        format.xml  { head :ok }
      end
    end
```

---

</SwmSnippet>

## Search and clone methods

<SwmSnippet path="/app/controllers/calagator/events_controller.rb" line="91">

---

The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="92:8:8" line-data="    # GET /events/search">`search`</SwmToken> method initializes a search for events using the <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="94:6:8" line-data="      @search = Event::Search.new(params)">`Event::Search`</SwmToken> class and reuses the index atom builder for rendering. The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="105:3:3" line-data="    def clone">`clone`</SwmToken> method creates a new event by cloning an existing one and prompts the user to update the fields.

```

    # GET /events/search
    def search
      @search = Event::Search.new(params)

      # setting @events so that we can reuse the index atom builder
      @events = @search.events

      flash[:failure] = @search.failure_message
      return redirect_to root_path if @search.hard_failure?

      render_events(@events)
    end

    def clone
      @event = Event::Cloner.clone(Event.find(params[:id]))
      flash[:success] = 'This is a new event cloned from an existing one. Please update the fields, like the time and description.'
      render 'new'
    end
```

---

</SwmSnippet>

## Private methods

<SwmSnippet path="/app/controllers/calagator/events_controller.rb" line="110">

---

The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="30:1:1" line-data="      render_event @event">`render_event`</SwmToken> and <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="21:1:1" line-data="      render_events @events">`render_events`</SwmToken> methods handle rendering events in various formats (HTML, XML, JSON, ICS, etc.). The <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="13:4:4" line-data="    before_action :find_and_redirect_if_locked, only: %i[edit update destroy]">`find_and_redirect_if_locked`</SwmToken> method checks if an event is locked and redirects with an error message if it is.

```

    private

    def render_event(event)
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render xml: event.to_xml(root: 'events', include: :venue) }
        format.json { render json: event.to_json(include: :venue) }
        format.ics  { render ics: [event] }
      end
    end

    # Render +events+ for a particular format.
    def render_events(events)
      respond_to do |format|
        format.html # *.html.erb
        format.kml  # *.kml.erb
        format.ics  { render ics: events || Event.future.non_duplicates }
        format.atom { render template: 'calagator/events/index' }
        format.xml  { render xml: events.to_xml(root: 'events', include: :venue) }
        format.json { render json: events.to_json(include: :venue) }
      end
    end

    def find_and_redirect_if_locked
      @event = Event.find(params[:id])
      if @event.locked?
        flash[:failure] = 'You are not permitted to modify this event.'
        redirect_to root_path
      end
    end
  end
end
```

---

</SwmSnippet>

This concludes the walkthrough of the <SwmToken path="/app/controllers/calagator/events_controller.rb" pos="8:3:3" line-data="  class EventsController &lt; Calagator::ApplicationController">`EventsController`</SwmToken> in the Calagator application. The controller is designed to handle all aspects of event management, ensuring proper validation, handling of duplicates, and rendering in multiple formats.

<SwmMeta version="3.0.0" repo-id="Z2l0aHViJTNBJTNBY2FsYWdhdG9yJTNBJTNBY2hyaXNicnVt" repo-name="calagator"><sup>Powered by [Swimm](https://app.swimm.io/)</sup></SwmMeta>
