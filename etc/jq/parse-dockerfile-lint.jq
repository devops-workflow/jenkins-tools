#
# jq filter for parsing dockerfile-lint output into 1 liners that Jenkins Warning plugin can parse
#
# Arguments:
#   file        relative path to Dockerfile or image
#
# Written for jq 1.5
# Author: Steven Nemetz
#
# Output format:
#  filename:priority:line number:category:message
#
.[].data?[]
 | "\($file):\(.level):" +
   if .line > 0 then
     "\(.line)"
   else
     "0"
   end +
   ":" +
   if .instruction then
     "\(.instruction)"
   elif .label then
     "\(.label)"
   else
     "misc"
   end +
   ":" +
   # Form message field by combining: message, description, reference_url array, and lineContent
   # Might reformat this later
   "\(.message)" +
   if .lineContent and (.lineContent | length > 0) then
     " Line=\(.lineContent)"
   else
     ""
   end +
   if .description then
     " Reason=\(.description)"
   else
     ""
   end +
   if .reference_url then
     " Reference=" + (.reference_url | join(""))
   else
     ""
   end
