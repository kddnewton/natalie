require_relative './cpp_backend/transform'
require_relative '../string_to_cpp'

module Natalie
  class Compiler
    class CppBackend
      include StringToCpp

      def initialize(instructions, compiler_context:)
        @instructions = instructions
        @compiler_context = compiler_context
        @symbols = {}
        @inline_functions = {}
        @top = []
      end

      def generate
        string_of_cpp = transform_instructions
        out = merge_cpp_with_template(string_of_cpp)
        reindent(out)
      end

      private

      def transform_instructions
        transform = Transform.new(
          @instructions,
          top: @top,
          compiler_context: @compiler_context,
          symbols: @symbols,
          inline_functions: @inline_functions,
        )
        transform.transform
      end

      def merge_cpp_with_template(string_of_cpp)
        @compiler_context[:template]
          .sub('/*' + 'NAT_DECLARATIONS' + '*/') { declarations }
          .sub('/*' + 'NAT_OBJ_INIT' + '*/') { init_object_files.join("\n") }
          .sub('/*' + 'NAT_EVAL_INIT' + '*/') { init_matter }
          .sub('/*' + 'NAT_EVAL_BODY' + '*/') { string_of_cpp }
      end

      def declarations
        [
          object_file_declarations,
          symbols_declaration,
          @top.join("\n")
        ].join("\n\n")
      end

      def init_matter
        [
          init_symbols.join("\n"),
          init_dollar_zero_global,
        ].compact.join("\n\n")
      end

      def object_file_declarations
        object_files.map { |name| "Value init_#{name.tr('/', '_')}(Env *env, Value self);" }.join("\n")
      end

      def symbols_declaration
        "static SymbolObject *#{symbols_var_name}[#{@symbols.size}] = {};"
      end

      def init_object_files
        object_files.map do |name|
          "init_#{name.tr('/', '_')}(env, self);"
        end
      end

      def init_symbols
        @symbols.map do |name, index|
          "#{symbols_var_name}[#{index}] = SymbolObject::intern(#{string_to_cpp(name.to_s)}, #{name.to_s.bytesize});"
        end
      end

      def init_dollar_zero_global
        return if @compiler_context[:is_obj]

        "env->global_set(\"$0\"_s, new StringObject { #{@compiler_context[:source_path].inspect} });"
      end

      def symbols_var_name
        static_var_name('symbols')
      end

      def static_var_name(suffix)
        "#{@compiler_context[:var_prefix]}#{suffix}"
      end

      def object_files
        rb_files = Dir[File.expand_path('../../../../src/**/*.rb', __dir__)].map do |path|
          path.sub(%r{^.*/src/}, '')
        end.grep(%r{^([a-z0-9_]+/)?[a-z0-9_]+\.rb$})
        list = rb_files.sort.map { |name| name.split('.').first }
        ['exception'] + # must come first
          (list - ['exception']) +
          @compiler_context[:required_cpp_files].values
      end

      def reindent(code)
        out = []
        indent = 0
        code
          .split("\n")
          .each do |line|
            indent -= 4 if line =~ /^\s*\}/
            indent = [0, indent].max
            if line.start_with?('#')
              out << line
            else
              out << line.sub(/^\s*/, ' ' * indent)
            end
            indent += 4 if line.end_with?('{')
          end
        out.join("\n")
      end
    end
  end
end
