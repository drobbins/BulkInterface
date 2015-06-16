BulkInterface = 
    defaultDelimiter: "	" # Tab, copied from Excel
    action: -> console.log BulkInterface.message
    lookupCollection: (name) -> 
        if Meteor.isClient then window[name] else global[name]
    parse: (rawData, options) ->
        if options.delimiter
            parsedData = Papa.parse rawData,
                header: true
                delimiter: options.delimiter
        else
            # Papa Parse doesn't detect tabs pasted from Excel for some reason, so we have to check for that
            preview = Papa.parse rawData,
                header: true
                preview: 10
            if (_.any preview.errors, (err) -> err.code == "UndetectableDelimiter")
                # If the delimiter was not detectable, use the default delimiter
                parsedData = Papa.parse rawData,
                    header: true
                    delimiter: BulkInterface.defaultDelimiter #"\t" "   "
            else
                parsedData = Papa.parse rawData, header: true
        parsedData

Meteor.methods
    "bulkInterfaceUpsert": (collectionName, rows, key, fields) ->
        collection = BulkInterface.lookupCollection collectionName
        results = []
        rows.forEach (row) ->
            rowData =  _.pick(row, fields)
            if key
                selector = {}
                selector[key] = row[key]
                result = collection.upsert selector, $set: rowData#, (err, result) ->
                if result.insertedId
                    results.push key: row[key], _id: row._id, status: type: "inserted", insertedId: result.insertedId
                else
                    results.push key: row[key], _id: row._id, status: type: "updated", numberAffected: result.numberAffected
            else
                collection.insert rowData
        return results

if Meteor.isClient

    Template.bulkInterface.onCreated ->
        # Set up reactive vars for later use
        @data.parsedDataCollection = new Mongo.Collection null
        @data.fields = new ReactiveVar @data.allowedFields?.split(",")
        @data.usedDelimiter = new ReactiveVar null

    Template.bulkInterface.events
        "click button.parse": (e, t) ->

            # Get the value of the text area, and shrink it.
            rawData = t.$("textarea").val()
            t.$("textarea").attr("rows", "5")

            # Papa Parse doesn't detect tabs pasted from Excel for some reason, so we have to check for that
            parsedData = BulkInterface.parse rawData, delimiter: @delimiter

            # Populate the data object with a few parameters
            if not @allowedFields then @fields.set parsedData.meta.fields
            @usedDelimiter.set parsedData.meta.delimiter

            # Put the parsed rows into a temporary collection
            @parsedDataCollection.remove {}
            parsedData.data.forEach (row) => @parsedDataCollection.insert row

            # Display the parsed data
            $(e.target).trigger "redrawTable"

            # Reflect our success in the buttons
            t.$("button.parse").removeClass("btn-primary").addClass("btn-success")
            t.$("button.save").removeClass("btn-default").addClass("btn-primary").attr("disabled", false)

        "focus textarea[name=bulk-interface-value]": (e) ->
            $(e.target).attr("rows", "25")

        "click button.save": (e, t) ->
            Meteor.call "bulkInterfaceUpsert", @targetCollection, @parsedDataCollection.find().fetch(), @key, @fields.get(), (err, results) =>
                results?.forEach (result) =>
                    @parsedDataCollection.update result._id, $set: _status: result.status
                $(e.target).trigger "redrawTable"
                t.$("button.save").removeClass("btn-primary").addClass("btn-success")

        "redrawTable": ->
            # Display the parsed data
            $(".bulk-interface-table").dataTable
                destroy: true
                data: @parsedDataCollection.find().fetch()
                columns: @fields.get().map (field) -> data: field, title: field
                rowCallback: (row, data, index) ->
                    rowClass = switch data._status?.type
                        when "inserted" then "success"
                        when "updated" then "warning"
                        when "error" then "danger"
                        else ""
                    $(row).addClass rowClass

    Template.bulkInterface.helpers
        count: -> @parsedDataCollection.find().count()
        fields: -> @fields.get()?.join(", ")
        displayDelimiter: ->
            switch @usedDelimiter.get()
                when "\t", "    " then "tab"
                else @usedDelimiter.get()
        rows: -> @parsedDataCollection.find()