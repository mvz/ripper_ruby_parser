module RipperRubyParser
  module SexpHandlers
    module Blocks
      def process_method_add_block(exp)
        _, call, block = exp.shift 3
        block = process(block)
        args = block[1]
        stmt = block[2].first
        call = process(call)
        make_iter call, args, stmt
      end

      def process_brace_block(exp)
        handle_generic_block exp
      end

      def process_do_block(exp)
        handle_generic_block exp
      end

      def process_params(exp)
        if exp.size == 6
          _, normal, defaults, splat, rest, block = exp.shift 6
        else
          _, normal, defaults, splat, rest, kwargs, doublesplat, block = exp.shift 8
        end

        args = []
        args += normal.map { |id| process(id) } if normal
        args += defaults.map { |sym, val| s(:lasgn, process(sym)[1], process(val)) } if defaults

        args << process(splat) unless splat.nil? || splat == 0
        args += rest.map { |it| process(it) } if rest
        args += handle_kwargs kwargs if kwargs
        args << s(:dsplat, process(doublesplat)) if doublesplat
        args << process(block) unless block.nil?

        s(:args, *args)
      end

      def process_block_var(exp)
        _, args, _ = exp.shift 3

        names = process(args)

        convert_special_args names
      end

      def process_begin(exp)
        _, body = exp.shift 2

        body = process(body)
        strip_typeless_sexp(body)
      end

      def process_rescue(exp)
        _, eclass, evar, block, after = exp.shift 5
        rescue_block = map_body(block)
        rescue_block << nil if rescue_block.empty?

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
          arr << create_assignment_sub_type(process(evar), s(:gvar, :$!))
        end

        s(
          s(:resbody, s(:array, *arr), *rescue_block),
          *process(after))
      end

      def process_bodystmt(exp)
        _, body, rescue_block, else_block, ensure_block = exp.shift 5

        body = map_body body

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

        body = wrap_in_block(body)

        body = if body.nil?
                 s()
               else
                 s(body)
               end

        body
      end

      def process_rescue_mod(exp)
        _, scary, safe = exp.shift 3
        s(:rescue, process(scary), s(:resbody, s(:array), process(safe)))
      end

      def process_ensure(exp)
        _, block = exp.shift 2
        strip_typeless_sexp safe_wrap_in_block map_body(block)
      end

      def process_next(exp)
        _, args = exp.shift 2
        if args.empty?
          s(:next)
        else
          s(:next, handle_return_argument_list(args))
        end
      end

      def process_break(exp)
        _, args = exp.shift 2
        if args.empty?
          s(:break)
        else
          s(:break, handle_return_argument_list(args))
        end
      end

      def process_lambda(exp)
        _, args, statements = exp.shift 3
        old_type = args.sexp_type
        args = convert_special_args(process(args))
        args = 0 if args == s(:args) && old_type == :params
        make_iter(s(:call, nil, :lambda),
                  args,
                  wrap_in_block(map_body(statements)))
      end

      private

      def handle_generic_block(exp)
        _, args, stmts = exp.shift 3
        args = process(args)
        # FIXME: Symbol :block is irrelevant.
        s(:block, args, s(wrap_in_block(map_body(stmts))))
      end

      def handle_kwargs(kwargs)
        kwargs.map do |sym, val|
          symbol = process(sym)[1]
          if val
            s(:kwarg, symbol, process(val))
          else
            s(:kwarg, symbol)
          end
        end
      end

      def strip_typeless_sexp(block)
        case block.length
        when 0
          s(:nil)
        when 1
          block[0]
        else
          block
        end
      end

      def make_iter(call, args, stmt)
        args ||= 0
        if stmt.nil?
          s(:iter, call, args)
        else
          s(:iter, call, args, stmt)
        end
      end
    end
  end
end
