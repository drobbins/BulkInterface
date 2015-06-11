BulkInterface = 
    defaultDelimiter: "	" # Tab, copied from Excel
    action: -> console.log BulkInterface.message

if Meteor.isClient

    Template.bulkInterface.onCreated ->
        # Set up reactive vars for later use
        @data.parsedDataCollection = new Mongo.Collection null
        @data.fields = new ReactiveVar null

    Template.bulkInterface.events
        "click button.parse": (e, t) ->
            #change textarea[name=bulk-interface-value]
            rawData = t.$("textarea").val()

            t.$("textarea").attr("rows", "5")

            # Papa Parse doesn't detect tabs pasted from Excel for some reason, so we have to check for that
            preview = Papa.parse rawData,
                header: true
                preview: 10
            if (_.any preview.errors, (err) -> err.code == "UndetectableDelimiter")
                # If the delimiter was not detectable, use the default delimiter
                parsedData = Papa.parse rawData,
                    header: true
                    delimiter: BulkInterface.defaultDelimiter #"\t" "	"
            else
                parsedData = Papa.parse rawData, header: true

            # Populate the data object with a few parameters
            @fields.set parsedData.meta.fields

            @parsedDataCollection.remove {}
            parsedData.data.forEach (row) => @parsedDataCollection.insert row

            $(".bulk-interface-table").dataTable
                destroy: true
                data: @parsedDataCollection.find().fetch()
                columns: @fields.get().map (field) -> data: field, title: field

        "focus textarea[name=bulk-interface-value]": (e) ->
            $(e.target).attr("rows", "25")

    Template.bulkInterface.helpers
        count: -> @parsedDataCollection.find().count()
        fields: -> @fields.get()
        rows: -> @parsedDataCollection.find()