class CSVReader
	CSVError = Class.new(Exception)
	def initialize(text, file = "(csvfile)")
		@text = text.gsub(/\r\n/, "\n")
		if @text[-1] != "\n"
			@text << "\n"
		end
		@file = file
	end	
	def parse
		@current = []
		@result = [@current]
		@pos = 1
		@char = @text[0]
		@line = 1
		@col = 0
		@last = nil
		while (p = gettoken)
			case p[0]
			when :newline
				@current << "" if @last == :comma
				if peekchar != nil
					@current = []
					@result << @current
				end
			when :comma
				if @last == :comma || @last == :newline || @last == nil
					@current << ""
				end
			when :token
				if @last == :token
					myraise "Unexpected token"
				end
				@current << p[1]
			when :eof
				break
			end
			@last = p[0]
		end
		@result
	end
	
	def myraise(a)
		raise CSVError.new("%s:%d:%d %s" % [@file, @line, @col, a])
	end
	
	def getchar
		r = @char
		@char = @pos >= @text.size ? nil : @text[@pos, 1]
		@pos += 1
		if r == "\n"
			@line += 1
			@col = 0
		else
			@col += 1
		end
		r
	end
	
	def peekchar
		@char
	end
	
	
	def gettoken
		case peekchar
		when nil
			[:eof]
		when ","
			getchar
			[:comma]
		when "\n"
			getchar
			[:newline]
		when '"' 
			getchar
			str = ""
			loop do
				case peekchar
				when nil
					myraise "unexpected EOF"
				when '"'
					getchar
					if peekchar == '"'
						getchar
						str << '"'
					else
						break
					end
				else
					str << getchar
				end
			end
			[:token, str]
		else
			str = getchar
			loop do
				case peekchar
				when ',', "\n", nil
					break
				else
					str << getchar
				end
			end
			[:token, str]
		end
	end
	
	def self.test_run(str)
		begin
			csv = ->text{ CSVReader.new(text).parse }
			eval str
		rescue 
			p $!
			nil
		end
	end
	
	def self.test_exception(str)
		begin
			csv = ->text{ CSVReader.new(text).parse }
			eval str
			false
		rescue CSVError
			true
		end
	end
	
	def self.test_one(r, str)
		unless test_run(str)
			puts r
			puts "#{str}"
		end
	end
	
	def self.test_ex(r, str)
		unless test_exception(str)
			puts r
			puts "#{str}"
		end
	end
	
	def self.tests
		lines = {}
		set_trace_func proc{|*e|
			lines[e[2]] = 1 if e[1] == "csv.rb" && e[2] 
		}
		test_one("should parse basic 1", "csv['123'] == [['123']]")
		test_one("should parse basic 2", "csv['1,2,3'] == [['1', '2', '3']]")
		test_one("should parse quote 1", %{csv['"12,3"'] == [['12,3']]})
		test_one("should parse quote 2", %{csv['"12\n3"'] == [["12\n3"]]})
		test_one("should parse quote 3", %{csv['"12\n34""56""78"'] == [["12\n34\\"56\\"78"]]})
		test_one("should parse multiline", %{csv['1,2,3\n4,5,6\n7,8,9'] == [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]})
		test_one("should parse multiline", %{csv['1,2,3\n\n4,5,6\n7,8,9\n'] == [["1", "2", "3"], [], ["4", "5", "6"], ["7", "8", "9"]]})
		test_one("should parse multiline", %{csv['"1,2,3\n4,5,6\n7,8,9"'] == [["1,2,3\n4,5,6\n7,8,9"]]})
		test_ex("should raise error/unexpected EOF in quote", %{csv['"123']})
		test_ex("should raise error/unexpected token", %{csv['"123" 567']})
		test_one("should raise no error", %{csv[',,,'] == [["", "", "", ""]]})
		test_one("should raise no error", %{csv[',,,\n'] == [["", "", "", ""]]})
		set_trace_func nil
		linestext = File.read(__FILE__).split("\n")
		r = ((1..107).select do |i|
			t = linestext[i - 1]
			!lines[i] && 
				t.strip != "end"   && 
				t.strip != ""      && 
				!t.index("class")  && 
				!t.index("Class")  &&
				!t.index("when")   &&
				!t.index("def")    &&
				!t.index("else")   
		end.to_a)
		p r unless r.empty?
	end
	
end


