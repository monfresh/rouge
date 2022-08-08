# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Bunch < RegexLexer
      title "Bunch"
      desc "Syntax for Bunch.app File"
      aliases 'bunch'
      tag 'bunch'
      filenames '*.bunch'

      commands = [
        "display",
        "dark mode on",
        "dark mode off",
        "dark mode",
        "light mode",
        "do not disturb on",
        "do not disturb off",
        "do not disturb",
        "dnd on",
        "dnd off",
        "dnd",
        "hide dock",
        "dock hide",
        "show dock",
        "dock show",
        "dock left",
        "dock right",
        "dock bottom",
        "dock",
        "desktop show",
        "desktop hide",
        "hide desktop",
        "show desktop",
        "hide menu bar",
        "show menu bar",
        "desktop",
        "wallpaper",
        "screen",
        "audio input",
        "audio output",
        "input source",
        "audio",
        "notify",
        "sleep",
        "awake",
        "log",
        "sc",
        "shortcut",
        "short"
      ]

      state :comment do
        rule %r((/\*+)(.*?)(\*+/))m do
          groups Comment::Hashbang, Comment::Multiline, Comment::Hashbang
        end
        rule %r((?<= |^)(#+|/{2,})( .*?)$) do
          groups Comment::Hashbang, Comment::Single
        end
      end

      state :basics do
        rule %r/\s+/m, Text
        rule %r(^(-{2,}|[=>#])[\-=># ]*\[), Comment::Special, :fragment
        rule %r(^-{3,}\s*$), Comment::Doc, :frontmatter
        rule %r(^_{3,}\s*$), Name::Builtin
        mixin :comment
        mixin :query
        rule %r(( {4}|\t)*((?:else )?if|else|end\b)(.*?)), Name::Builtin::Pseudo, :conditional
        rule %r(\S+:\/\/\S+), Name::Constant
        rule %r/^(?!-).*?(?==)/, Keyword::Variable, :assignment
        # Commands
        rule %r/\((#{commands.join('|')})/, Keyword::Reserved, :command
        # Variables
        rule %r/[$%]\{/, Punctuation, :var_inner
        # Apps
        rule %r(^\|?(!+\s*)?[%@]?(@|\\|\w).*?(?= // | # |$)), Name::Constant
        # Scripts
        rule %r(^(\|?!*|\w.*?=\s*)[$*&](?!\{)), Name::Function, :script
        rule %r(!*<<?), Name::Class, :snippet
        rule %r(^-), Name::Decorator, :file
        mixin :interp
        mixin :delay
      end

      state :script do
        mixin :heredoc
        rule %r((?= // | # |$)), Name::Function, :pop!
      end

      state :query do
        rule %r(((\?[\{\[]|[\}\]]|\?<(.*?))\s*(".*?")?)), Str::Double
      end

      state :delay do
        rule %r(\s*~\d+), Name::Entity
      end

      state :snippet do
        rule %r($), Name::Class, :pop!
        mixin :delay
        mixin :optional
        mixin :root
        mixin :variable
        rule %r(#(?=\S)), Keyword::Namespace, :frag_inner
        rule %r([^#]+?(?=#| // | # | ~\d| \?"|$)), Name::Label
      end

      state :frag_inner do
        rule %r(.*?(?=[$%]\{| // | # | ~\d| \?"|$)), Keyword::Namespace, :pop!
        mixin :variable
      end

      state :optional do
        rule %r( \?".*?"), Str::Double
      end

      state :fragment do
        rule %r([^\]]+), Keyword::Namespace
        rule %r(\](.*?)$), Comment::Special, :pop!
        mixin :delay
      end

      state :variable do
        rule %r/[$%]\{/, Punctuation, :var_inner
      end

      state :var_inner do
        rule %r(\}), Punctuation, :pop!
        rule %r([^:\}]+?(?=[:\}])), Operator
        rule %r(:\S.*?(?=\})), Str::Double
      end

      state :file do
        mixin :comment
        rule %r((?=\n))m, Name::Decorator, :pop!
        # rule %r(^\s*(\S+)\s*(=)\s*(.*?)(?= // | # |$)) do
        #   groups Keyword::Variable, Punctuation, Keyword::Variable
        # end
        # mixin :assignment
        rule %r(^\s*[\w\d_]+\s*(?==)), Keyword::Variable, :assignment
        mixin :variable
      end

      state :assignment do
        mixin :heredoc
        rule %r((?=\n))m, Keyword::Variable, :pop!
        rule %r(^\s*(\S+)\s*(?==)), Keyword::Declaration
        rule %r((?<==)\s*(.*?)(?= // | # |$)), Name::Attribute
        rule %r(=), Punctuation
        rule %r([$*&][^\{].*?(?= // | # |$)), Name::Function
        rule %r( (//|#) .*), Comment
        mixin :query
        mixin :optional
        mixin :variable
      end

      state :heredoc do
        rule %r((?:(```)([\s\S]*?)\1|<< *([A-Z]+)([\s\S]*?)(\3)))m, Str::Single, :pop!
      end

      state :frontmatter do
        rule %r(^-{3,}\s*$), Comment::Doc, :pop!
        rule %r(^(\S.*?)(:)(.*?)$) do
          groups Name::Variable::Global, Punctuation::Indicator, Name::Attribute
        end
        # rule %r((?<=:).*?$), Name::Attribute
        # rule %r(^\S.*?(?=:)), Name::Variable::Global
        # rule %r(:), Punctuation::Indicator
      end

      state :command do
        rule %r/\)/, Keyword::Reserved, :pop!
        mixin :variable
        mixin :root
        mixin :delay
      end

      state :conditional do
        rule %r/(AND|OR|NOT)/, Operator::Word
        rule %r/end\b/, Name::Builtin::Pseudo, :pop!
        rule %r/(weekday|time)/, Keyword::Reserved
        rule %r/\b(is|does|has)( not( have)?)?\b/, Operator::Word
        rule %r/\b((less|greater) than(or equal( to)?)?|(equals?)|[!><\^$*=]=|(start|end)s? with|contains?|running|child|parent( is)?|open(ing)?|clos(ed|ing)?)\b/, Operator::Word
        mixin :variable
        mixin :root
      end

      state :root do
        mixin :basics
        rule %r([~^*!%&\[\]()<>|+=@:;,./?-]), Operator
        rule %r/"(\\\\|\\"|[^"])*"/, Str::Single
        rule %r/'(\\\\|\\'|[^'])*'/, Str::Double
      end

      state :bracket_interp do
        rule %r/\}/, Str::Interpol, :pop!
        mixin :root
      end

      state :paren_interp do
        rule %r/(AND|OR|NOT)/, Operator::Word
        rule %r/\)/, Punctuation::Indicator, :pop!
        mixin :root
      end

      state :interp do
        rule %r/\\$/, Str::Escape # line continuation
        rule %r/\\./, Str::Escape
        rule %r/\$\{/, Str::Interpol, :bracket_interp
        rule %r/\(/, Punctuation::Indicator, :paren_interp
      end
    end
  end
end
