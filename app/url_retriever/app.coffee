jQuery ($) ->
    class UrlResult extends Backbone.Model
        defaults:
            url: ""
            content: ""
            selectedTag: null

    # Model for each tag in the summary view.
    class Tag extends Backbone.Model
        defaults:
            tagName: ""
            usageCount: ""
            isSelected: false

    # View for each tag in the summary view.
    class TagView extends Backbone.View
        events:
            click: "click"

        template: _.template $("#tag_summary_entry").html()

        initialize: ->
            _.bindAll @, "render", "click"

        click: ->
            @trigger "click", @model.get('tagName')

        render: ->
            html = @template @model.toJSON()
            @setElement $(html)
            return @

    # Summary view
    class UrlSummaryView extends Backbone.View
        el: "div.url_summary"

        events: {}

        initialize: ->
            _.bindAll @, "render", "tag_click", "add_tag"
            @list = @$ 'ul', @$el

            @listenTo @model, "change:selectedTag change:content", @render

        get_tag_matches: (html_string) ->
            pattern = /<([A-Z][A-Z0-9]*)\b[^>]*>/gmi
            resultDict = {}

            while (matchArray = pattern.exec html_string) != null
                tagName = matchArray[1].toUpperCase()
                if tagName not of resultDict
                    resultDict[tagName] = 0
                resultDict[tagName] += 1

            return resultDict

        add_tag: (data) ->
            console.log data
            model = new Tag(data)
            selectedTag = @model.get "selectedTag"
            if selectedTag == model.get "tagName"
                model.set "isSelected", true
            view = new TagView
                model: model

            @listenTo(view, "click", @tag_click);
            @list.append(view.render().el);

        tag_click: (e) ->
            @model.set "selectedTag", e

        render: ->
            @list.html ""
            results = @get_tag_matches @model.get('content')

            tagNames = _.keys results
                .sort()
            for name in tagNames
                count = results[name]
                console.log "#{name} - #{count}"
                @add_tag
                    tagName: name
                    usageCount: count

            return @

    # Code View
    class UrlResultView extends Backbone.View
        el: "div.url_detail"
        events: {}

        template: _.template $("#url_detail").html()

        initialize: ->
            _.bindAll @, "render"
            @listenTo @model, "change:selectedTag change:content", @render

        render: ->
            content = @highlight_tags @model.get('content'), @model.get('selectedTag')
            @model.set "display_content", content
            @$el.html @template(@model.toJSON())

            return @

        highlight_tags: (searchString, tagName) ->
            if not tagName
                return _.escape searchString

            pattern = "</?" + tagName + "\\b[^>]*>"
            re = new RegExp pattern, "gmi"

            resultString = ""
            first = 0
            last = 0

            # find each match
            while (matchArray = re.exec searchString) != null
                last = matchArray.index
                # get all of string up to match, concatenate
                resultString += _.escape searchString.substring(first, last)

                # add matched, with class
                resultString += "<span class='found'>#{_.escape matchArray[0]}</span>"
                first = re.lastIndex


            # finish off string
            resultString += _.escape searchString.substring(first,searchString.length)
            return resultString

    # Main application
    class AppView extends Backbone.View
        # There are 2 actions the user can take: 1. submit a new URL; 2. Click on a tag for highlighting.

        el: "div#container"

        events:
            "click    button.submit"  : "set_url"
            "keypress #url_input"     : "on_keypress"


        initialize: ->
            _.bindAll @, "url_success", "render", "on_keypress"
            @$input = @$ "#url_input"

            @model = new UrlResult()

            @summaryView = new UrlSummaryView model: @model
            @resultView = new UrlResultView model: @model

            @listenTo @model, "change:url", @fetch_url_content
            @listenTo @model, "change:content", -> @$el.removeClass("intro").addClass("normal")
            @$input.val window.location

            @$el.addClass("intro")

        # For pressing enter in the url box
        on_keypress: (e) ->
            @set_url() if e.keyCode == 13

        set_url: ->
            @model.set "url", @$input.val()

        fetch_url_content: ->
            url = @model.get "url"
            $.get "api/retrieve_url?url=" + encodeURIComponent(url), @url_success

        url_success: (data) ->
            @model.set
                content: data.content
                selectedTag: null

    window.AppView = AppView;
    window.App = new AppView();