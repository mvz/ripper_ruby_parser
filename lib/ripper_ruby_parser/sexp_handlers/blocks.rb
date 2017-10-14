module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for blocks and related constructs
    module Blocks
      def process_method_add_block(exp)
        _, call, block = exp.shift 3
        block = process(block)
        _, args, stmt = block
        call = process(call)
        make_iter call, args, stmt.first
      end

      def process_brace_block(exp)
        handle_generic_block exp
      end

      def process_do_block(exp)
        handle_generic_block exp
      end

      def process_params(exp)
        _, normal, defaults, splat, rest, kwargs, doublesplat, block = exp.shift 8

        args = []
        args += handle_normal_arguments normal
        args += handle_default_arguments defaults
        args += handle_splat splat
        args += handle_normal_arguments rest
        args += handle_kwargs kwargs
        args += handle_double_splat doublesplat
        args += handle_block_argument block

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
        rescue_block = map_process_sexp_body_compact(block)
        rescue_block << nil if rescue_block.empty?

        arr = []
        if eclass
          if eclass.first.is_a? Symbol
            arr += process(eclass).sexp_body
          else
            arr << process(eclass[0])
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

        body = body_wrap_in_block map_process_sexp_body_compact(body)

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

        body_wrap_in_block body
      end

      def process_rescue_mod(exp)
        _, scary, safe = exp.shift 3
        s(:rescue, process(scary), s(:resbody, s(:array), process(safe)))
      end

      def process_ensure(exp)
        _, block = exp.shift 2
        strip_typeless_sexp safe_unwrap_void_stmt process(block)
      end

      def process_next(exp)
        _, args = exp.shift 2
        args = handle_return_argument_list(args)
        if args.empty?
          s(:next)
        else
          s(:next, args)
        end
      end

      def process_break(exp)
        _, args = exp.shift 2
        args = handle_return_argument_list(args)
        if args.empty?
          s(:break)
        else
          s(:break, args)
        end
      end

      def process_lambda(exp)
        _, args, statements = exp.shift 3
        old_type = args.sexp_type
        args = convert_special_args(process(args))
        args = 0 if args == s(:args) && old_type == :params
        make_iter(s(:call, nil, :lambda),
                  args,
                  unwrap_nil(process(statements)))
      end

      private

      def handle_generic_block(exp)
        type, args, stmts = exp.shift 3
        args = process(args)
        s(type, args, s(unwrap_nil(process(stmts))))
      end

      def handle_normal_arguments(normal)
        return [] unless normal
        map_process_list normal
      end

      def handle_default_arguments(defaults)
        return [] unless defaults
        defaults.map { |sym, val| s(:lasgn, process(sym)[1], process(val)) }
      end

      def handle_splat(splat)
        if splat && splat != 0
          [process(splat)]
        else
          []
        end
      end

      def handle_kwargs(kwargs)
        return [] unless kwargs
        kwargs.map do |sym, val|
          symbol = process(sym)[1]
          if val
            s(:kwarg, symbol, process(val))
          else
            s(:kwarg, symbol)
          end
        end
      end

      def handle_double_splat(doublesplat)
        return [] unless doublesplat
        [s(:dsplat, process(doublesplat))]
      end

      def handle_block_argument(block)
        return [] unless block
        [process(block)]
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

      def body_wrap_in_block(statements)
        case statements.length
        when 0
          s()
        when 1
          s(statements.first)
        else
          s(s(:block, *statements))
        end
      end
    end
  end
end
