#	Interpreter : interpretting the scheme(dialect of lisp) using python
#	This is done in 3 steps.
#		1. Parsing : Tokenize and group individual sub-expression into list
#		2. Creating a global_env(Dictionary and grammar book)
#		3. Evauating the parsed tokens using known globa_env
#

def parse(program)
  return read_the_tokens(tokenize(program))
end


#insert space between '(' and the first argument
#convert the string into a list.
def tokenize(str)
	#gsub: substitute; split: converts string to array
  tokens = str.gsub('(', ' ( ').gsub(')',' ) ').split()	
  return tokens
end


#club all the sub-expressions into a list
def read_the_tokens(tokens)
	if tokens.length == 0
		raise "unexpected end of file"
	end
	
	token = tokens.shift

	if token == "("
		list = []
		while tokens[0] != ")"
			#group all the subexpressions in the list!
			list << read_the_tokens(tokens)
		end
		tokens.shift #this is to shift the closing braces
		return list
	elsif token == ")"
		raise "unexpected closing braces"
	else
		converted_atom = atom(token)
		return converted_atom 
	end
end


#convert parsed tokens to integers, float or symbol
def atom(token)
	if token =~ /^[0-9]+$/
		return token.to_i
	elsif token =~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/
		return token.to_f
	else
		return token.to_sym
	end
end

class Env < Hash
	def initialize(params=[], args=[], outer_env=nil)
		if outer_env != nil
			outer_env.each do |k, v|
				self[k] = v
			end
		end
		params.zip(args).each{|p| key, value = p; self[key] = value}#  store(*p)}
	end
end


#mapping the operators to the relevant operation call.
#analogous to dictionary and a grammar book
def standard_env()
  ops = [:+, :-, :*, :/, :>, :<, :>=, :<=, :==]
	env = Env.new #initialize a env hash
	ops.each{|op| env[op] = lambda{|a,b| a.send(op,b)}}
	env.update({ 
		:length => lambda{|x| x.length}, 
		:cons => lambda{|x, y| [x]+y},
		:car => lambda{|x| x[0]}, 
		:cdr => lambda{|x| x[1..-1]}, 
		:append => lambda{|x,y| x+y},
		:list => lambda{|*xs| xs}, 
		:list? => lambda{|x| x.is_a? Array}, 
		:null? => lambda{|x| x==nil},
		:symbol? => lambda{|x| x.is_a? Symbol}, 
		:not => lambda{|x| !x}, 
		:display => lambda{|x| p x}
	})
  return env
end

def procedure(params, body, outer_env)
	procedure_call = lambda do |*args|
		new_env = Env.new(params, args, outer_env)
		value = eval(body,new_env)
		return value
	end
	return procedure_call
end

	
#function that uses parsed token and evaluates the expression using the global_env
def eval(tokens, env)
	if tokens.is_a? Symbol  # variable reference
		return env[tokens]
	elsif !tokens.is_a? Array   #constant literal
		return tokens
	elsif tokens[0] == :quote   #quote expression
		_, exp = tokens 
		return exp
	elsif tokens[0] == :if			#if test conseq alt
		_, test, conseq, alt = tokens
		return eval(eval(test, env) ? conseq : alt, env)
	elsif tokens[0] == :define #define var exp
		env[tokens[1]] = eval(tokens[2], env)
#	elsif tokens[0] == "set!" #set 
#		env.set(x[1], eval(x[2], env))
	elsif tokens[0] == :lambda  #set user-defined procedure
		_, params, body = tokens
		return procedure(params, body, env)
	else
		proc = eval(tokens[0],env)	#collect the operator to evaluate
		args = []
		for exp in tokens[1..-1] do 
			args.push(eval(exp, env))	#collect arguments
		end
		value =	proc.call *args[0..-1]
		return value
	end
end

env = standard_env()

while 1
	puts "enter a scheme expression:> "
	expr = $stdin.gets.chomp
	abstract_tree = parse(expr)
	value = eval(abstract_tree, env)
	puts "#{value}"
end


