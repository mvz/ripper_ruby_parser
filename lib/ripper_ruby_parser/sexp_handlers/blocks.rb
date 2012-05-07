module RipperRubyParser
  module SexpHandlers
    module Blocks
      def process_method_add_block exp
        _, call, block = exp.shift 3
        block = process(block)
        args = block[1]
        stmt = block[2].first
        call = process(call)
        make_iter call, args, stmt
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
          process(id)
        end

        assigns = [*defaults].map do |pair|
          sym = process(pair[0])
          args << sym
          val = process(pair[1])
          s(:lasgn, sym[1], val)
        end

        args << process(rest) unless rest.nil?
        args << process(block) unless block.nil?
        args << s(:block, *assigns) if assigns.length > 0

        s(:args, *args)
      end

      def process_block_var exp
        _, args, _ = exp.shift 3

        names = process(args)

        args_to_assignment names
      end

      def process_begin exp
        _, body = exp.shift 2

        block = process(body)[1]

        strip_wrapping_block(block.compact)
      end

      def process_rescue exp
        _, eclass, evar, block, after = exp.shift 5
        rescue_block = map_body(block)

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
          easgn = s(:lasgn, evar, s(:gvar, :$!))
          arr << easgn
        end

        s(
          s(:resbody, s(:array, *arr), wrap_in_block(rescue_block)),
          *process(after))
      end

      def process_bodystmt exp
        _, body, rescue_block, else_block, ensure_block = exp.shift 5

        body = map_body body

        #unless rescue_block or ensure_block
        #  return s(:scope, s(:block, *body))
        #end

        body = wrap_in_block(body)

        body = if body.nil?
                 s()
               else
                 s(body)
               end

        if rescue_block
          body.push(*process(rescue_block))
          body << process(else_block) if else_block
          body = s(s(:rescue, *body))
        elsif else_block
          body << process(else_block)
        end

        if ensure_block
          body << process(ensure_block)
          body = s(s(:ensure, *body))
        end

        if body.length == 1 and body.first.sexp_type == :block
          s(:scope, *body)
        else
          s(:scope, s(:block, *body))
        end
      end

      def process_rescue_mod exp
        _, scary, safe = exp.shift 3
        s(:rescue, process(scary), s(:resbody, s(:array), process(safe)))
      end

      def process_ensure exp
        _, block = exp.shift 2
        wrap_in_block s(*map_body(block))
      end

      def process_next exp
        _, args = exp.shift 2
        if args.empty?
          s(:next)
        else
          s(:next, handle_return_argument_list(args))
        end
      end

      def process_break exp
        _, args = exp.shift 2
        if args.empty?
          s(:break)
        else
          s(:break, handle_return_argument_list(args))
        end
      end

      def process_lambda exp
        _, args, statements = exp.shift 3
        make_iter(s(:call, nil, :lambda, s(:arglist)),
                  args_to_assignment(process(args)),
                  *handle_potentially_typeless_sexp(statements))
      end

      private

      def handle_generic_block exp
        _, args, stmts = exp.shift 3
        # FIXME: Symbol :block is irrelevant.
        s(:block, process(args), s(handle_statement_list(stmts)))
      end

      def strip_wrapping_block(block)
        return block unless block.sexp_type == :block
        case block.length
        when 1
          s(:nil)
        when 2
          block[1]
        else
          block
        end
      end

      def arg_name_to_lasgn(name)
        case name.sexp_type
        when :lvar
          s(:lasgn, name[1])
        when :blockarg
          s(:lasgn, :"&#{name[1][1]}")
        when :splat
          if name[1].nil?
            s(:splat)
          else
            s(:splat, s(:lasgn, name[1][1]))
          end
        else
          name
        end
      end

      def make_iter call, args, stmt
        if stmt.nil?
          s(:iter, call, args)
        else
          s(:iter, call, args, stmt)
        end
      end

      def args_to_assignment names
        names.shift
        if names.length == 1 and names.first.sexp_type == :lvar
          s(:lasgn, names.first[1])
        elsif names.length == 1 and names.first.sexp_type == :masgn
          names.first
        else
          s(:masgn, s(:array, *names.map { |name| arg_name_to_lasgn(name) }))
        end
      end
    end
  end
end
