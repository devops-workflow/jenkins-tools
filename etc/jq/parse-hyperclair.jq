#
# jq filter for parsing hyperclair output into 1 liners that Jenkins Warning plugin can parse
#
# Written for jq 1.5
# Author: Steven Nemetz
#
# Output format:
#  filename;line number;category;type;priority;message
#
# Set to variable, then reference after if
# Got lost because of piping a lower level
#.filename = "\(.ImageName):\(.Tag)"
# | (.Layers[].Layer.Features[]
#
# First line is bad. So pipe to
# Will create duplicate and bad lines
# Need to pipe output to cleanup or figure out better way to do this
# | sort -u | tail -n+2
"\(.ImageName):\(.Tag);0;" +
(.Layers[].Layer.Features[]
  | if .Vulnerabilities then
      "\(.Name) - \(.Version);" +
      (.Vulnerabilities[] | "\(.Name);\(.Severity);" +
      if .Message then
        "\(.Message) "
      else
        ""
      end +
      "Reference: \(.Link)")
    else
      ""
    end
 )
