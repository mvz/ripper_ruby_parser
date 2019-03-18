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
        stmt = with_block_kwrest(kwrest) { process(stmt) }
        make_iter call, args, safe_unwrap_void_stmt(stmt)
      end

      def process_params(exp)
        _, normal, defaults, splat, rest, kwargs, doublesplat, block = exp.shift 8

        args = handle_normal_arguments normal
        args += handle_default_arguments defaults
        args += handle_splat splat
        args += handle_normal_arguments rest
        args += handle_kwargs kwargs
        args += handle_double_splat doublesplat
        args += handle_block_argument block

        s(:args, *args)
      end

      def process_rest_param(exp)
        _, ident = exp.shift 2
        s(:splat, process(ident))
      end

      def process_kwrest_param(exp)
        _, sym, = exp.shift 3
        process(sym)
      end

      def process_block_var(exp)
        _, args, = exp.shift 3

        names = process(args)

        convert_block_args names
      end

      def process_begin(exp)
        _, body = exp.shift 2

        body = convert_empty_to_nil_symbol process(body)
        s(:begin, body)
      end

      def process_rescue(exp)
        _, eclass, evar, block, after = exp.shift 5
        rescue_block = map_process_list_compact block.sexp_body
        rescue_block << nil if rescue_block.empty?

        capture = if eclass
                    if eclass.first.is_a? Symbol
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
                  else
                    s(:array)
                  end

        capture << create_assignment_sub_type(process(evar), s(:gvar, :$!)) if evar

        s(
          s(:resbody, capture, *rescue_block),
          *process(after))
      end

      def process_bodystmt(exp)
        _, main, rescue_block, else_block, ensure_block = exp.shift 5

        body = s()

        main = wrap_in_block map_process_list_compact main.sexp_body
        body << main if main

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

        wrap_in_block(body) || s()
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
        args = convert_method_args(process(args))
        args = nil if args == s(:args) && old_type == :params
        make_iter(s(:call, nil, :lambda),
                  args,
                  safe_unwrap_void_stmt(process(statements)))
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
            extract_node_symbol(process(sym)),
            process(val))
        end
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
          symbol = extract_node_symbol process(sym)
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

      def convert_empty_to_nil_symbol(block)
        case block.length
        when 0
          s(:nil)
        else
          block
        end
      end

      def make_iter(call, args, stmt)
        args.pop if args && args.last == s(:excessed_comma)
        args ||= 0
        if stmt.empty?
          s(:iter, call, args)
        else
          s(:iter, call, args, stmt)
        end
      end

      def wrap_in_block(statements)
        case statements.length
        when 0
          nil
        when 1
          statements.first
        else
          s(:block, *statements)
        end
      end

      def convert_block_args(args)
        args.map! do |item|
          if item.is_a? Symbol
            item
          else
            case item.sexp_type
            when :lvar
              item.last
            when :masgn
              args = item[1]
              args.shift
              s(:masgn, *convert_block_args(args))
            when :lasgn
              if item.length == 2
                item[1]
              else
                item
              end
            when *Methods::SPECIAL_ARG_MARKER.keys
              marker = Methods::SPECIAL_ARG_MARKER[item.sexp_type]
              name = extract_node_symbol item[1]
              :"#{marker}#{name}"
            else
              item
            end
          end
        end
      end
    end
  end
end
