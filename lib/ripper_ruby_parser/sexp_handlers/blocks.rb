module RipperRubyParser
  module SexpHandlers
    module Blocks
      def process_method_add_block exp
        _, call, block = exp.shift 3
        block = process(block)
        args = convert_block_args(block[1])
        stmt = block[2].first
        s(:iter, process(call), args, stmt)
      end

      def process_brace_block exp
        handle_generic_block exp
      end

      def process_do_block exp
        handle_generic_block exp
      end

      def process_params exp
        _, normal, defaults, rest, _, block = exp.shift 6

        args = [*normal].map do |id|
          identifier_node_to_symbol id
        end

        assigns = [*defaults].map do |pair|
          sym = identifier_node_to_symbol pair[0]
          val = process pair[1]
          s(:lasgn, sym, val)
        end

        if assigns.length > 0
          args += assigns.map {|lasgn| lasgn[1]}
          args << s(:block, *assigns)
        end

        unless rest.nil?
          name = identifier_node_to_symbol rest[1]
          args << :"*#{name}"
        end

        unless block.nil?
          name = identifier_node_to_symbol block[1]
          args << :"&#{name}"
        end

        s(:args, *args)
      end

      def process_begin exp
        _, body = exp.shift 2

        block = process(body)[1]

        strip_wrapping_block(block)
      end

      def process_rescue exp
        _, eclass, evar, block, _ = exp.shift 5
        rescue_block = s(*map_body(block))

        arr = []
        if eclass
          eclass = handle_potentially_typeless_sexp eclass
          if eclass.first.is_a? Symbol
            arr += eclass[1..-1]
          else
            arr << eclass[0]
          end
        end

        if evar
          evar = process(evar)[1]
          easgn = s(:lasgn, :e, s(:gvar, :$!))
          arr << easgn
        end

        s(:resbody, s(:array, *arr),
          wrap_in_block(rescue_block))
      end

      def process_rescue_mod exp
        _, scary, safe = exp.shift 3
        s(:rescue, process(scary), s(:resbody, s(:array), process(safe)))
      end

      private

      def handle_generic_block exp
        _, args, stmts = exp.shift 3
        s(:block, process(args), s(handle_statement_list(stmts)))
      end

      def strip_wrapping_block(block)
        case block.length
        when 1
          s(:nil)
        when 2
          block[1]
        else
          block
        end
      end

    end
  end
end
