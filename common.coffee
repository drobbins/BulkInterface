interfacesByName = {}

class Interface
    constructor: (options) ->
        if not options
            throw new Error "BulkInterface.Interface options argument is required"

        requiredKeys = ["name", "permissions", "collection"]
        if not (_.all requiredKeys, (requiredKey) -> _.has options, requiredKey)
            throw new Error "BulkInterface.Interface options must specify at least its name, collection, and permissions"


        if not (options.collection instanceof Mongo.Collection)
            throw new Error "BulkInterface.Interface option collection must be a Mongo.Collection"

        @name = options.name
        @collection = options.collection
        @permissions = options.permissions
        @allowedFields = options.allowedFields
        @key = options.key
        @options = _.omit options, "name", "collection", "permissions", "allowedFields", "key"

        # Register this interface in the index
        interfacesByName[@name] = @



BulkInterface = 
    defaultDelimiter: "	" # Tab, copied from Excel

    lookupCollection: (collection) ->
        if collection instanceof Mongo.Collection
            return collection
        else
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
            if (_.any preview.errors, (err) -> err.code == "UndetectableDelimiter") or (_.any preview.errors, (err) -> err.code == "TooManyFields")
                # If the delimiter was not detectable, use the default delimiter
                parsedData = Papa.parse rawData,
                    header: true
                    delimiter: BulkInterface.defaultDelimiter #"\t" "   "
            else
                parsedData = Papa.parse rawData, header: true
        parsedData

    Interface: Interface



Meteor.methods
    "BulkInterface.upsert": (interfaceName, rows) ->

        _interface = interfacesByName[interfaceName]
        key = _interface.key
        results = []


        makeResult = (row, response, type) ->
            if not type
                if typeof response is "string" or response.insertedId
                    type = "inserted"
                else
                    type = "updated"
            result =
                _id: row._id or response
                status:
                    type: type
                    rawResponse: response
            if key then result.key = row[key].trim()
            return result


        rows.forEach (row) ->

            if not _interface.permissions.update(Meteor.userId?() or null, row)
                results.push makeResult row, "[401] not permitted", "error"
            else
                rowData =  if _interface.allowedFields then _.pick(row, _interface.allowedFields) else _.omit(row, "_id")

                if key
                    selector = {}
                    selector[key] = row[key].trim()
                    response = _interface.collection.upsert selector, $set: rowData
                    results.push makeResult row, response
                else
                    response = _interface.collection.insert rowData
                    results.push makeResult row, response


        return results