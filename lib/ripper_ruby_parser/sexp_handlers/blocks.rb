# frozen_string_literal: true

module RipperRubyParser
  module SexpHandlers
    # Sexp handlers for blocks and related constructs
    module Blocks
      def process_method_add_block(exp)
        _, call, block = exp.shift 3
        _, args, stmt = block
        call = process(call)
        args = process(args)
        kwrest = kwrest_param(args) if args
        stmt = with_new_lvar_scope(kwrest) { process(stmt) }
        make_iter call, args, safe_unwrap_void_stmt(stmt)
      end

      # NOTE: Argument forwarding is handled differently in Ruby 3.0 and 3.1
      # 3.0: s(:params, nil, nil, s(:args_forward), nil, nil, nil, nil)
      # 3.1: s(:params, nil, nil, nil, nil, nil, s(:args_forward), :&)
      def process_params(exp)
        _, normal, defaults, splat, rest, kwargs, doublesplat, block = exp.shift 8

        args =
          handle_normal_arguments(normal) +
          handle_default_arguments(defaults) +
          handle_splat(splat) +
          handle_normal_arguments(rest) +
          handle_kwargs(kwargs) +
          handle_double_splat(doublesplat) +
          handle_block_argument(block)

        s(:args, *args)
      end

      def process_rest_param(exp)
        _, ident = exp.shift 2
        s(:splat, process(ident))
      end

      def process_kwrest_param(exp)
        _, sym, = exp.shift 3
        process(sym) || s(:lvar, :"")
      end

      def process_block_var(exp)
        _, args, shadowargs = exp.shift 3

        names = process(args)

        if shadowargs
          shadowargs = map_process_list(shadowargs).map { |item| item[1] }
          names << s(:shadow, *shadowargs)
        end

        convert_arguments names
      end

      def process_begin(exp)
        _, body, pos = exp.shift 3

        body = convert_void_stmt_to_nil_symbol process(body)
        with_position pos, s(:begin, body)
      end

      def process_rescue(exp)
        _, eclass, evar, block, after = exp.shift 5
        rescue_block = map_process_list_compact block.sexp_body
        rescue_block << nil if rescue_block.empty?

        capture = handle_rescue_class_list eclass

        capture << create_assignment_sub_type(process(evar), s(:gvar, :$!)) if evar

        s(s(:resbody, capture, *rescue_block), *process(after))
      end

      def process_bodystmt(exp)
        _, main, rescue_block, else_block, ensure_block = exp.shift 5

        body_list = []

        main_block = process(main)
        line = main_block.line
        body_list << main_block if main_block.sexp_type != :void_stmt

        body_list.push(*process(rescue_block)) if rescue_block
        body_list << process(else_block) if else_block
        body_list = [s(:rescue, *body_list)] if rescue_block

        if ensure_block
          body_list << process(ensure_block)
          body_list = [s(:ensure, *body_list)]
        end

        wrap_in_block(body_list, line)
      end

      def process_rescue_mod(exp)
        _, scary, safe = exp.shift 3

        s(:rescue, process(scary), s(:resbody, s(:array), process(safe)))
      end

      def process_ensure(exp)
        _, block = exp.shift 2
        convert_empty_to_nil_symbol safe_unwrap_void_stmt process(block)
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
        args = convert_arguments(process(args))
        statements = process(statements)
        line = args.line || statements.line
        args = nil if args == s(:args) && old_type == :params
        call = s(:lambda)
        call.line = line

        make_iter call, args, safe_unwrap_void_stmt(statements)
      end

      private

      def handle_normal_arguments(normal)
        return [] unless normal

        map_process_list normal
      end

      def handle_default_arguments(defaults)
        return [] unless defaults

        defaults.map do |sym, val|
          s(:lasgn,
            make_symbol(process(sym)),
            process(val))
        end
      end

      def handle_splat(splat)
        if splat
          [process(splat)]
        else
          []
        end
      end

      def handle_kwargs(kwargs)
        return [] unless kwargs

        kwargs.map do |sym, val|
          symbol = make_symbol process(sym)
          if val
            s(:kwarg, symbol, process(val))
          else
            s(:kwarg, symbol)
          end
        end
      end

      def handle_double_splat(doublesplat)
        return [] unless doublesplat

        contents = process(doublesplat)
        case contents.sexp_type
        when :forward_args # Argument forwarding in Ruby 3.1
          [contents]
        else
          [s(:dsplat, contents)]
        end
      end

      def handle_block_argument(block)
        return [] unless block
        return [] if block == :& # Part of argument forwarding in Ruby 3.1; ignore

        [process(block)]
      end

      def handle_rescue_class_list(eclass)
        if eclass.nil?
          s(:array)
        elsif eclass.first.is_a? Symbol
          eclass = process(eclass)
          body = eclass.sexp_body
          if eclass.sexp_type == :mrhs
            body.first
          else
            s(:array, *body)
          end
        else
          s(:array, process(eclass.first))
        end
      end

      LVAR_MATCHER = Sexp::Matcher.new(:lvar, Sexp._)
      NUMBERED_PARAMS = (1..9).map { |it| :"_#{it}" }.freeze

      def make_iter(call, args, stmt)
        args[-1] = nil if args && args.last == s(:excessed_comma)

        args ||= count_numbered_lvars(stmt)

        if stmt.empty?
          s(:iter, call, args)
        else
          s(:iter, call, args, stmt)
        end
      end

      def count_numbered_lvars(stmt)
        lvar_names = (LVAR_MATCHER / stmt).map { |it| it[1] }
        (NUMBERED_PARAMS & lvar_names).length
      end
    end
  end
end
