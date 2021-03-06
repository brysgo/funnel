#
# The Rule Class
# --------------
# The rule class is a singleton that is created for every new
# rule definition. It computes and maintains information that
# is essential for the Funnel runtime.

class Rule

  # Get a rule that is already defined
  @get: ( name ) -> @f._rules[name]

  # Clear cached dependency info
  clear: ->
    @_dependencies = undefined
    @_passes = undefined
    @_bound = undefined

  # Construct a new rule
  # and save it as a singleton
  constructor: ( @name, @_fn ) ->

  # Get the rules dependancies from the function's code
  # and store it for later
  dependencies: =>
    unless @_dependencies?
      fnStr = @_fn.toString()
      params = fnStr.slice(fnStr.indexOf('(')+1, fnStr.indexOf(')'))
      params = params.match(/([^\s,]+)/g)
      if params
        @_dependencies = (@constructor.get(p) for p in params)
      @_dependencies = [] if !@_dependencies? or undefined in @_dependencies
    return @_dependencies

  # Get a list of all the dependencies that will be satisfied
  # after this function is called, optionally pass a list of
  # dependencies to check against this list
  passes: ( dependencies=undefined ) =>
    unless @_passes
      @_passes = []
      for d in @dependencies()
        @_passes.push(d)
        @_passes.concat(d.passes())
      @_passes.push(@)
    return @_passes unless dependencies?

    # Check if dependancies are passed
    return -1 if @_passes.length is 0
    for dependency in dependencies
      return -1 unless dependency in @_passes
    return @_passes.length

  # Allow rules to bind to this rule's completion
  bind: ( rule ) =>
    @_bound ?= []
    @_bound.push(rule)

  # Run this rule and trigger the next ones
  run: ( args ) =>
    # Accept either a result hash or an argument list
    results = undefined
    d = @dependencies()
    if args
      if Object::toString.call(args) == '[object Array]'
        results = {}
        results[name] = args[i] for name, i in d
      else
        results = args
        args = (args[x.name] for x in d)
    # Create the run context
    context =
      emit: (val) =>
        results_ = JSON.parse(JSON.stringify(results))
        results_[ @name ] = val
        @_bound ?= []
        rule.run( results_ ) for rule in @_bound
    # Run the rule
    @_fn.apply( context, args )

#### Export Rule
@Rule = Rule
module?.exports = Rule
