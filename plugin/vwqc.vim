
" -----------------------------------------------------------------
" ------------------------ VWQC PLUG-IN ---------------------------
" -----------------------------------------------------------------
" function Annotation
" function ExitAnnotation
" function AnnotationToggle
" function GoToReference
" function GoBackFromReference
" function InterviewFormat
" function SetUpReportVariables 
" function FigureOutWhatKindOfSearchResultThisIs
" function ProcessInterviewLines
" function ProcessAnnotations
" function TagReport
" function GetInfoFromSearchResultBuffer
" function UpdateSubcode
" function GlossaryDef
" function TagLinter
" function VWSReport
" function TagFillWithChoice
" function ChangeTagFillOption
" function JustQuotes
" function CheckForTagListOmniCompleteTag
" function GetTagUpdate
" function GenDictTagList
" function CurrentTagsPopUpMenu
" function NoTagListNotice 
" function SortTagDefs
" function TrimLeadingPartialSentence
" function TrinTrailingPartialSentence
" function Attributes
" function ColSort
" function GetTagDef
" function CreateTagDict

if exists('g:loaded_vwqc') || &compatible
  finish
endif
let g:loaded_vwqc = 1


" -------------------- VWQC PLUG-IN FUNCTIONS ---------------------
" -----------------------------------------------------------------

" -----------------------------------------------------------------
" One of three annotation function. This first one opens an annotation window.
" If its a new window it names it and adds a title label. It also adds the
" coders initials.
" -----------------------------------------------------------------

function! Annotation() abort
	" -----------------------------------------------------------------
	" Find the wiki we're in and get its wiki number.
	" We have to add 1 because Vimwiki counts its wikis within a list and
	" lists are indexed starting at zero. However when we make our wiki numbers
	" in our .vimrc we start at 1.
	" -----------------------------------------------------------------
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1
	" -----------------------------------------------------------------
	" Use the wiki number we just found to get the configuration variables
	" for this wiki. These are part of the wiki declaration. We added
	"   wiki_x.label_start_col
	"   wiki_x.interview_label_pattern
	" -----------------------------------------------------------------
	let g:built_label_start_col_var_name = "g:wiki_" . g:wiki_number . ".label_start_col"
	let g:border_offset = eval(g:built_label_start_col_var_name)
	let g:label_offset = g:border_offset + 2

	let g:built_interview_label_var_name = "g:wiki_" . g:wiki_number . ".interview_label_regex"
	let g:interview_label_regex = eval(g:built_interview_label_var_name)

	let g:built_coder_initials = "g:wiki_" . g:wiki_number . ".coder_initials"
	let g:coder_initials = eval(g:built_coder_initials)
	" -----------------------------------------------------------------
	" Look for a tag-line number combination. Note that we'll have to
	" Standardize this. searchpos() returns a list with the line and 
	" column positions of the first character of the match.
	" First log current line number so we can check later to see if the 
	" match is on that line. Then find the match.

	" Initialize list of tags on line.
	" Assume there is at least one tag on the line
	" Identify the current line number
	" Move cursor to the beginning of the line so that forward searches
	" start there.
	let g:list_of_tags_on_line = ""
	let g:is_tag_on_line = 1
	let g:current_line = line(".")
	execute "normal! 0"

	" Loop until not more tags are found on the line.
	while (g:is_tag_on_line == 1)
		" --------------------------------------------------
		" Search for a tag without going past the end of the file.
		" --------------------------------------------------
		let g:match_line = search(':\a\w\{1,}:', "W")
		" --------------------------------------------------
		" If we found a tag (ie. The search function doesn't
		" return a zero) and that tag is found on the current line
		" then add the tag to our list. Note search will move the
		" cursor to the first character of the match.
		" --------------------------------------------------
		if (g:match_line == g:current_line)
			" -------------------------------------------
			" Copy the tag we found and move the cursor one
			" character past the tag. Then add that tag to the
			" list of tags we're building.
			" -------------------------------------------
			execute "normal! vf:yeel"
			let g:this_tag = @@
			let g:list_of_tags_on_line = g:list_of_tags_on_line . g:this_tag . " "
		else
			" No more tags
			let g:is_tag_on_line = 0
		endif 
	endwhile	
	" -----------------------------------------------------------------
	" Move cursor back to the start of current_line because the search
	" function may have moved the cursor beyond current_line
	" -----------------------------------------------------------------
	call cursor(g:current_line, 0)
	execute "normal! 0"
	" -----------------------------------------------------------------
	" Initialize variables and move cursor to the beginning of the line.
	" -----------------------------------------------------------------
	let g:match_line = 0
	let g:match_col = 0
	" -----------------------------------------------------------------
	" Search for the label - number pair on the line. searchpos() 
	" returns a list with the line and column numbers of the cursor
	" position of the first character in the match. searchpos() with
	" the arguments we supplied will move the cursor to the first
	" character of match we found. So because we started in column 1
	" if the column remains at 1 we know we didn't find a match.
	" -----------------------------------------------------------------
	let g:tag_search_regex = g:interview_label_regex . '\: \d\{4}'
	let g:tag_search = searchpos(g:tag_search_regex)
	let g:match_line = g:tag_search[0]
	let g:match_col  = virtcol('.')
	" -----------------------------------------------------------------
	" Now we have to decide what to do with the result based on where
	" the cursor ended up. The first thing we test is whether the match
	" line is the same as the current line. This may not be true if it 
	" had to go down one or more lines to find a match. If its true we
	" execute the first part of the if statement. Otherwise we print an 
	" error message and reposition the cursor at the beginning of the 
	" line where we started.
	" -----------------------------------------------------------------
	if g:current_line == g:match_line
		" -----------------------------------------------------------------
		" Test to see if the match starts at g:label_offset or 
		" g:label_offset + 1. g:label_offset refers to the column
		" that we that we formatted the label to start at.
	 	" If there is an existing link to an annotation page the 
		" link will be surrounded by Vimwiki's square bracket link 
		" notation []. The opening bracket will cause the match to 
		" be bumped over to the right by 1 column, hence the match
		" will start at g:label_offset + 1.
		" -----------------------------------------------------------------
		if g:match_col == g:label_offset		
			" -----------------------------------------------------------------
			" Re-find the label-number pair and yank it. The next
			" line builds the Vimwiki link. There must be a Vimwiki
			" plug command that does this but I couldn't figure it 
			" out. Then we follow the link to a new page. The final 
			" two lines add the title to the new page and position 
			" the cursor at the bottom of the page.
			" -----------------------------------------------------------------
			execute "normal! " . '0/' . g:interview_label_regex . '\:\s\{1}\d\{4}' . "\<CR>" . 'vf|hhy'
			execute "normal! gvc[]\<ESC>Plli()\<ESC>\"\"P\<ESC>"
			execute "normal \<Plug>VimwikiVSplitLink"
			execute "normal! \<C-W>x\<C-W>l:vertical resize 80\<CR>"
			put =expand('%:t')
			execute "normal! 0kdd/.md\<CR>xxxI:\<ESC>2o\<ESC>"
		        execute "normal! i" . g:list_of_tags_on_line . "// \:" . g:coder_initials . "\:  \<ESC>"
			startinsert 
		elseif g:match_col == (g:label_offset + 1)
			" -----------------------------------------------------------------
			" Re-find the link, but don't yank it. This places the 
			" cursor on the first character of the match. The next
			" line follows the link to the page and the final line 
			" places the cursor at the bottom of the annotation 
			" page.
			" -----------------------------------------------------------------
			execute "normal! " . '0/' . g:interview_label_regex . '\:\s\{1}\d\{4}' . "\<CR>"
			execute "normal \<Plug>VimwikiVSplitLink"
			execute "normal! \<C-W>x\<C-W>l:vertical resize 80\<CR>"
			execute "normal! Go\<ESC>V?.\<CR>jd2o\<ESC>"
		        execute "normal! i" . g:list_of_tags_on_line . "// \:" . g:coder_initials . "\:  \<ESC>"
			startinsert
		else
			echo "Something is not right here."		
		endif
	else
		echo "No match found on this line"
		call cursor(g:current_line, 0)
	endif
endfunction

" -----------------------------------------------------------------
" This function exists an annotation window and resizes remaining windows
" -----------------------------------------------------------------

function! ExitAnnotation() abort
	" -----------------------------------------------------------------
	" Find the wiki we're in and get its wiki number.
	" We have to add 1 because Vimwiki counts its wikis within a list and
	" lists are indexed starting at zero. However when we make our wiki numbers
	" in our .vimrc we start at 1.
	" -----------------------------------------------------------------
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1
	" -----------------------------------------------------------------
	" Use the wiki number we just found to get the configuration variables
	" for this wiki. These are part of the wiki declaration. We added
	"   wiki_x.coder_initials
	" -----------------------------------------------------------------
	let g:built_coder_initials = "g:wiki_" . g:wiki_number . ".coder_initials"
	let g:coder_initials = eval(g:built_coder_initials)
	" -----------------------------------------------------------------
	" Remove blank lines from the bottom of the annotation, and copy the
	" remaining bottom line to test_line 
	" -----------------------------------------------------------------
	execute "normal! Go\<ESC>V?.\<CR>jdVy\<ESC>"
	let g:test_line = @@
	" -----------------------------------------------------------------
	" Build a regex that looks for the coder tag at the begining of the line and
	" then only white space to the carriage return character.
	" -----------------------------------------------------------------
	let g:find_coder_tag_regex = '\v:' . g:coder_initials . ':\s*\n'
	let g:is_orphaned_tag = match(g:test_line, g:find_coder_tag_regex) 
	" -----------------------------------------------------------------
	" If you don't find anything following the coder tag, ie there is no
	" annotations following, delete the line.
	" -----------------------------------------------------------------
	if (g:is_orphaned_tag != -1)
		execute "normal! dd"
	endif
	" -----------------------------------------------------------------
	" Close annotation window and resize remaining windows.
	" -----------------------------------------------------------------
	execute "normal! :wq\<CR>\<C-W>h\<C-W>h:vertical resize 60\<CR>\<C-W>l"
endfunction

" -----------------------------------------------------------------
" This function determines what kind of buffer the cursor is in (annotation or
" interview) and decides whether to call Annotation() or ExitAnnotation()
" -----------------------------------------------------------------

function! AnnotationToggle() abort
	" -----------------------------------------------------------------
	" Initialize variables. These are global variables so we don't want to 
	" inherit values from previous TagReport() function calls.
	" -----------------------------------------------------------------
	let g:wiki_number = 0
	" -----------------------------------------------------------------
	" Find the wiki we're in and get its wiki number.  We have to add 1 because 
	" Vimwiki counts its wikis within a list and lists are indexed starting at 
	" zero. However when we make our wiki numbers in our .vimrc we start at 1.
	" -----------------------------------------------------------------
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1
	" -----------------------------------------------------------------
	" Get the extension for the current wiki 
	" -----------------------------------------------------------------
	let g:built_wiki_extension = "g:wiki_" . g:wiki_number . ".ext"
	let g:wiki_extension = eval(g:built_wiki_extension)
	" -----------------------------------------------------------------
	" Initialize buffer type variables
	" -----------------------------------------------------------------
	let g:is_interview = 0
	let g:is_annotation = 0
	let g:is_summary = 0

	let g:buffer_name = expand('%:t')
	let g:where_extension_starts = strridx(g:buffer_name, g:wiki_extension)
	let g:buffer_name = g:buffer_name[0 :(g:where_extension_starts - 1)]
	" -----------------------------------------------------------------
	" Check to see if it is a Summary file. It it is nothing happens.
	" -----------------------------------------------------------------
	let g:summary_search_match_loc = match(g:buffer_name, "Summary")
	if (g:summary_search_match_loc == -1)	" not found
		let g:is_summary = 0		" FALSE
	else
		let g:is_summary = 1		" TRUE
	endif
	" -----------------------------------------------------------------
	" Check to see if the current search result buffer is
	" an annotation file. If it is ExitAnnotation() is called.
	" -----------------------------------------------------------------
	let g:pos_of_4_digit_number = match(g:buffer_name, ' \d\{4}')
	if (g:pos_of_4_digit_number == -1)      " not found
		let g:is_annotation = 0		" FALSE
	else
		let g:is_annotation = 1		" TRUE
		call ExitAnnotation()		
	endif
	" -----------------------------------------------------------------
	" Check to see if the current search result buffer is
	" from an interview file. If it is Annotation() is called.
	" -----------------------------------------------------------------
	if (g:is_annotation == 1) || (g:is_summary == 1)
		let g:is_interview = 0		" FALSE
	else
		let g:is_interview = 1		" TRUE
		call Annotation()
	endif
endfunction

" -----------------------------------------------------------------
" Finds a label-line number pair in a Summary buffer and uses that to to to
" that location in an interview buffer.
" -----------------------------------------------------------------

function! GoToReference() abort
	" -----------------------------------------------------------------
	" Change the pwd to that of the current wiki.
	" -----------------------------------------------------------------
	execute "normal! :cd %:p:h\<CR>"
	" -----------------------------------------------------------------
	" Find the wiki we're in and get its wiki number.
	" -----------------------------------------------------------------
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1
	" -----------------------------------------------------------------
	" Get label regex for this wiki
	" -----------------------------------------------------------------
	let g:built_interview_label_var_name = "g:wiki_" . g:wiki_number . ".interview_label_regex"
	let g:interview_label_regex = eval(g:built_interview_label_var_name)
	" -----------------------------------------------------------------
	" Find target file name.
	" -----------------------------------------------------------------
	execute "normal! 0/" . g:interview_label_regex . ':\s\d\{4}' . "\<CR>" . 'vf:hy'
	let g:target_file = @@
	let g:target_file_ext = vimwiki#vars#get_wikilocal('ext')
	let g:target_file = g:target_file . g:target_file_ext
	" -----------------------------------------------------------------
	" Find target line number "
	" -----------------------------------------------------------------
	execute "normal! `<"
	execute "normal! " . '/\d\{4}' . "\<CR>"
	execute "normal! viwy"
	let g:target_line = @@
	" -----------------------------------------------------------------
	" Save buffer number of current file to register 'a' so you can return here
	" -----------------------------------------------------------------
	let @a = bufnr('%')
	" -----------------------------------------------------------------
	" Go to target file
	" -----------------------------------------------------------------
	execute "normal :e " . g:target_file . "\<CR>"
	execute "normal! gg"
	" -----------------------------------------------------------------
	" Find line number and center on page
	" -----------------------------------------------------------------
	execute "normal! gg"
	call search(g:target_line)
	execute "normal! zz"
endfunction

" -----------------------------------------------------------------
" Returns to the place called by GoToReference().
" -----------------------------------------------------------------

function! GoBackFromReference() abort
	execute "normal! :b\<C-r>a\<CR>"
endfunction

" -----------------------------------------------------------------
" This function formats interview text to use in for Vimwiki interview coding. 
" -----------------------------------------------------------------
function! InterviewFormat(interview_label) abort
	" -----------------------------------------------------------------
	" Find the wiki we're in and get its wiki number.
	" We have to add 1 because Vimwiki counts its wikis within a list and
	" lists are indexed starting at zero. However when we make our wiki numbers
	" in our .vimrc we start at 1.
	" -----------------------------------------------------------------
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1
	" -----------------------------------------------------------------
	" Use the wiki number we just found to get the configuration variables
	" for this wiki. These are part of the wiki declaration. We added
	"   wiki_x.label_start_col
	"   wiki_x.par_limit
	"   wiki_x.interview_label_pattern
	" -----------------------------------------------------------------
	let g:built_label_start_col_var_name = "g:wiki_" . g:wiki_number . ".label_start_col"
	let g:border_offset = eval(g:built_label_start_col_var_name)
	let g:border_offset_less_one = g:border_offset - 1

	let g:built_par_limit_var_name = "g:wiki_" . g:wiki_number . ".par_limit"
	let g:par_limit = eval(g:built_par_limit_var_name)
	let g:par_limit_expression = "set formatprg=par\\ w" . g:par_limit

	let g:built_interview_label_var_name = "g:wiki_" . g:wiki_number . ".interview_label_regex"
	let g:interview_label_regex = eval(g:built_interview_label_var_name)

	let g:built_interview_header_template = "g:wiki_" . g:wiki_number . ".interview_header_template"
	let g:interview_header_template = eval(g:built_interview_header_template)
	" -----------------------------------------------------------------
	" Add interview header template
	" In this next session the first line resets the formatprg option to match what
	" is set in the wiki configuration. This tells Vim to use the BASH program par 
	" as the text formatter when you type gq.
	" In second line below the whole text is selected (ggVG) then gq is run, 
	" and finally the cursor is reset to the top of the buffer (gg).
	" see http://vimcasts.org/episodes/formatting-text-with-par/ for how par works with vim.		
	" -----------------------------------------------------------------
	execute g:par_limit_expression
	execute "normal! ggVGgqgg"
	" -----------------------------------------------------------------
	" This next section reformats the AWS Transcribe time stamps to change square 
	" brackets to round ones. Square brackets conflict with Vimwiki links that
	" also use square brackets. setline() writes a line. It uses line (the first
	" argument) with the second argument which is the whole substitute() command.
	" The substitute command starts with the current line (getline(line)) and then
	" finds the [0:14:12] AWS time stamps in square brackets and replaces them with
	" parentheses.
	" -----------------------------------------------------------------
	for line in range(1, line('$'))
		call setline(line, substitute(getline(line), '\[\(\d:\d\d:\d\d\)\]', '\(\1\)', 'g'))
        endfor
	" -----------------------------------------------------------------
	" These next few lines add a fixed end of line at the column specified in the 
	" wiki configuration for the wiki_x.label_start_col value. 
	" See top of this function for var calculations. To do this it
	" it turns on virtualedit mode. This allows you to select columns outside the
	" range of your line. The second line just selects the first column. I 
	" first tried to position the cursor using the cursor() command but it 
	" placed the cursor in a different place if the row had an apostrophe. Don't
	" know why. The third line overwrites the content added in the second line with 
	" pipe symbols. The final line turns virtualedit mode off.
	" -----------------------------------------------------------------
	set virtualedit=all
	execute "normal! gg\<C-v>Gy" . g:border_offset_less_one . "|p"
	execute "normal! gg" . g:border_offset . "|\<C-v>G" . g:border_offset . "|r\|"
	set virtualedit=""
	" -----------------------------------------------------------------
	" Reposition cursor at the top of the buffer
	" -----------------------------------------------------------------
	execute "normal! gg"
	" -----------------------------------------------------------------
	" Add labels at the end of the line using the label passed into the 
	" function as an argument.
	" -----------------------------------------------------------------
	for line in range(1, line('$'))
		call cursor(line, 0)
		execute "normal! A " . a:interview_label . "\: \<ESC>"
	endfor
	" -----------------------------------------------------------------
	" Add line numbers to the end of each line and the second
	" column of pipe symbols
	" -----------------------------------------------------------------
	for line in range(1, line('$'))
		let g:line_number_to_add = printf("%04d \| ", line)
		call setline(line, substitute(getline(line), '$', g:line_number_to_add, 'g'))
        endfor
	" -----------------------------------------------------------------
	" Reposition cursor at the top of the buffer
	" -----------------------------------------------------------------
	execute "normal! gg"
	execute "normal! :.-1read " . g:interview_header_template . "\<CR>gg"
endfunction

function! SetUpReportVariables(search_term_passed_in) abort
	" -----------------------------------------------------------------
	" Initialize variables. 
	" -----------------------------------------------------------------
	let g:built_tag_summary_path = ""
	let g:tag_summary_path = ""
	let g:tag_summary_file = ""
	let g:built_interview_label_var_name = ""
	let g:interview_label_regex = ""
	let g:wiki_number = 0
	let g:num_search_results = 0 
	" -----------------------------------------------------------------
	" Find the wiki we're in and get its wiki number.  We have to add 1 because 
	" Vimwiki counts its wikis within a list and lists are indexed starting at 
	" zero. However when we make our wiki numbers in our .vimrc we start at 1.
	" -----------------------------------------------------------------
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1
	" -----------------------------------------------------------------
	" Change the pwd to that of the current wiki.
	" -----------------------------------------------------------------
	execute "normal! :cd %:p:h\<CR>"
	" -----------------------------------------------------------------
	" Set a mark R in the current buffer which is the buffer where your
	" report will appear.
	" -----------------------------------------------------------------
	execute "normal! :delmarks R\<CR>"
	execute "normal! ggmR"
	" -----------------------------------------------------------------
	" Get the file extension for this wiki.
	" -----------------------------------------------------------------
	let g:built_wiki_extension_var = "g:wiki_" . g:wiki_number . ".ext"
	let g:wiki_extension = eval(g:built_wiki_extension_var)
	" -----------------------------------------------------------------
	" Build the path and file name for the tag summary output file.
	" -----------------------------------------------------------------
	let g:built_tag_summary_path = "g:wiki_" . g:wiki_number . ".tag_summaries"
	let g:tag_summary_path = eval(g:built_tag_summary_path)
	let g:tag_summary_path = expand(g:tag_summary_path)
	let g:tag_summary_file = g:tag_summary_path . a:search_term_passed_in . ".csv"
	" -----------------------------------------------------------------
	" Get the label regex for this interview wiki
	" -----------------------------------------------------------------
	let g:built_interview_label_var_name = "g:wiki_" . g:wiki_number . ".interview_label_regex"
	let g:interview_label_regex = eval(g:built_interview_label_var_name)
endfunction

function! FigureOutWhatKindOfSearchResultThisIs() abort
	" -----------------------------------------------------------------
	" Reset variables at the top of the for loop
	" -----------------------------------------------------------------
	let g:is_interview = 0
	let g:is_annotation = 0
	let g:is_summary = 0
	let g:annotation_text = ""
	let g:current_buffer_name = ""
	" -----------------------------------------------------------------
	" Get the current Location List search result
	" -----------------------------------------------------------------
	execute "normal! Vy"
	let g:location_list_search_result_line = @@
	" -----------------------------------------------------------------
	" Find sections delimited by pipes (|)
	" -----------------------------------------------------------------
	let g:sections_delim_by_pipes = split(g:location_list_search_result_line, "|")
	" -----------------------------------------------------------------
	" Extract the buffer name from the Location List search result line.
	" Find the locations of the last path delimiter ("/") and the wiki
	" file extension (.md) then subset the first section_delim_by_pipes
	" result based on these positions. Note the + 1 andn - 1 are because
	" VimwikiSearchTags output pads the this field with spaces.
	" -----------------------------------------------------------------
	let g:last_slash = strridx(g:sections_delim_by_pipes[0], "/")
	let g:where_extension_starts = strridx(g:sections_delim_by_pipes[0], g:wiki_extension)
	let g:current_buffer_name = g:sections_delim_by_pipes[0][(g:last_slash + 1): (g:where_extension_starts - 1)]
	" -----------------------------------------------------------------
	" Extract the Location List search result line and column numbers.
	" -----------------------------------------------------------------
	let g:line_col_field_list = split(g:sections_delim_by_pipes[1], " ")
	let g:search_result_line = str2nr(g:line_col_field_list[0])
	let g:search_result_col = str2nr(g:line_col_field_list[2])
	" -----------------------------------------------------------------
	" Extra the Location List result line. Rebuild the rest of the
	" Location List result line. There's a leading space taken off with
	" the g:result_line[1:]
	" -----------------------------------------------------------------
	let g:result_line = ""
	let g:number_of_sections = len(g:sections_delim_by_pipes) - 1
	for l:section in range(2, g:number_of_sections)
		" -----------------------------------------------------------------
		" 
		" -----------------------------------------------------------------
		if (l:section < g:number_of_sections)
			let g:result_line = g:result_line .  g:sections_delim_by_pipes[l:section] . "|"
		else
			let g:result_line = g:result_line .  g:sections_delim_by_pipes[l:section]
		endif
	endfor
	let g:result_line = g:result_line[1:]
	" -----------------------------------------------------------------
	" Check to see if the current search result buffer is
	" a Summary file. If it is don't process it. If the
	" word "Summary" isn't found match() will return -1. We will assume
	" that a file name without summary in it is an interview file.
	" -----------------------------------------------------------------
	let g:summary_search_match_loc = match(g:current_buffer_name, "Summary")

	if (g:summary_search_match_loc == -1)	" not found
		let g:is_summary = 0		" FALSE
	else
		let g:is_summary = 1		" TRUE
	endif
	" -----------------------------------------------------------------
	" Check to see if the current search result buffer is
	" an annotation file. 
	" -----------------------------------------------------------------
	let g:pos_of_4_digit_number = match(g:current_buffer_name, ' \d\{4}')
	if (g:pos_of_4_digit_number == -1)      " not found
		let g:is_annotation = 0		" FALSE
	else
		let g:is_annotation = 1		" TRUE
		let g:annotation_lines_processed = g:annotation_lines_processed + 1
		let g:annotation_line_num_loc = match(g:current_buffer_name, ' \d\{4}')
		let g:current_annotation_line_number = str2nr(g:current_buffer_name[(g:annotation_line_num_loc + 1):])
	endif
	" -----------------------------------------------------------------
	" Check to see if the current search result buffer is
	" from an interview file.
	" -----------------------------------------------------------------
	if (g:is_annotation == 1) || (g:is_summary == 1)
		let g:is_interview = 0		" FALSE
	else
		let g:is_interview = 1		" TRUE
		" -----------------------------------------------------------------
		" Now we use the label regex for this wiki concatenated with a four-
		" digit number to look for the interview label - line number combination and
		" from this extract the current_interview_line_number.
		" -----------------------------------------------------------------
		let g:tag_search_regex = g:interview_label_regex . '\: \d\{4}'
		let g:interview_label_position = match(g:result_line, g:tag_search_regex)
		let g:interview_line_num_pos  = match(g:result_line, ' \d\{4}', g:interview_label_position)
		let g:current_interview_line_number = str2nr(g:result_line[(g:interview_line_num_pos + 1):(g:interview_line_num_pos + 4)])
		let g:interview_lines_processed = g:interview_lines_processed + 1
	endif
endfunction

function! ProcessInterviewLines(remove_metadata, write_records, search_term_passed_in) abort
	" -----------------------------------------------------------------
	" Take off the metadata (tags and line labels).
	" -----------------------------------------------------------------
	if a:remove_metadata == "Yes"
		let g:border_location = match(g:result_line, g:tag_search_regex) - 4
		let g:out_value = g:result_line[:g:border_location]
	endif
	" -----------------------------------------------------------------
	" Make sure if its the first interview line that we
	" have values for last_buffer_name and
	" last_interview_line_number.
	" -----------------------------------------------------------------
	if (g:interview_lines_processed == 1)
		let g:last_buffer_name = g:current_buffer_name
		let g:last_interview_line_number = g:current_interview_line_number - 1
		let g:block_count = 1
		" -----------------------------------------------------------------
		" Get g:first_row and g:current_buffer_length
		" from the interview document.
		" -----------------------------------------------------------------
		call GetInfoFromSearchResultBuffer(g:is_annotation)
	endif
	" -----------------------------------------------------------------
	" Decide how to process interview Location List
	" Results. If it is contiguous with the last interview line result.
	" -----------------------------------------------------------------
	if ((g:current_interview_line_number - g:last_interview_line_number) == 1) && (g:last_buffer_name == g:current_buffer_name)
		" --------------------------------------------------------------
		"  Add result line to the s register.
		" --------------------------------------------------------------
		if (g:interview_lines_processed == 1) 
			if (a:remove_metadata == "Yes")
				let @s = @s . "\n\n" . g:current_buffer_name . "\n\n" . g:out_value
			else
				let @s = @s . "\n-----------------\n\n" . g:result_line
			endif
		else
			if (a:remove_metadata == "Yes")
				let @s = @s . g:out_value
			else
				let @s = @s . g:result_line
			endif
		endif
		" --------------------------------------------------------------
		" Update last_buffer_name and
		" last_interview_line_number and last_write
		" --------------------------------------------------------------
		let g:last_buffer_name = g:current_buffer_name
		let g:last_interview_line_number = g:current_interview_line_number
		let g:last_write = "interview"
	" -----------------------------------------------------------------
	" If it is in the same interview but not contiguous
	" with the last interview line result.
	" -----------------------------------------------------------------
	elseif ((g:current_interview_line_number - g:last_interview_line_number) != 1) && (g:last_buffer_name == g:current_buffer_name)
		" --------------------------------------------------------------
		"  Add result line to the s register with a
		"  line feed character (\n) first.
		" --------------------------------------------------------------
		if (a:remove_metadata == "Yes")
			let g:formatted_line_number = printf("%04d", g:last_interview_line_number)
			let @s = @s . " " . g:current_buffer_name . ": " . g:formatted_line_number . "\n\n" . g:out_value
		else
			let @s = @s . "\n" . g:result_line
		endif
		" --------------------------------------------------------------
		" Update last_buffer_name and
		" last_interview_line_number
		" --------------------------------------------------------------
		let g:last_buffer_name = g:current_buffer_name
		let g:last_interview_line_number = g:current_interview_line_number
		let g:block_count = g:block_count + 1
		let g:last_write = "interview"
	" -----------------------------------------------------------------
	" If it is from a different interview than that last
	" interview line result. 
	" -----------------------------------------------------------------
	elseif (g:last_buffer_name != g:current_buffer_name)
		" --------------------------------------------------------------
		"  Add result line to the s register with a
		"  line feed character (\n) first.
		" --------------------------------------------------------------
		if (a:remove_metadata == "Yes")
			let g:formatted_line_number = printf("%04d", g:last_interview_line_number)
			let @s = @s . " " . g:last_buffer_name . ": " . g:formatted_line_number . "\n\n" . g:current_buffer_name . "\n\n" . g:out_value
		else
			let @s = @s . "\n-----------------\n\n" . g:result_line
		endif
		" --------------------------------------------------------------
		" Update last_buffer_name and
		" last_interview_line_number and block_count
		" --------------------------------------------------------------
		let g:last_buffer_name = g:current_buffer_name
		let g:last_interview_line_number = g:current_interview_line_number
		let g:block_count = 1
		let g:last_write = "interview"
		" -----------------------------------------------------------------
		" Get g:first_row and g:current_buffer_length
		" from the interview document.
		" -----------------------------------------------------------------
		call GetInfoFromSearchResultBuffer(g:is_annotation)
	endif
	" -----------------------------------------------------------------
	" Build output record
	" -----------------------------------------------------------------
	if a:write_records == "Yes"
		let g:interviewee_attributes = substitute(g:first_row, ":", ",", "g")

		let g:outline = a:search_term_passed_in . "," . g:current_buffer_name . ","
		let g:outline = g:outline . g:current_interview_line_number . "," 
		let g:outline = g:outline . g:current_buffer_length . ","
		let g:outline = g:outline . g:block_count . g:interviewee_attributes
		" -----------------------------------------------------------------
		" Write csv output lines.
		" -----------------------------------------------------------------
		if (g:interview_lines_processed == 1)
			" -----------------------------------------------------------------
			" Write line creating a new file.
			" -----------------------------------------------------------------
			call writefile([g:outline], g:tag_summary_file)
		else
			" -----------------------------------------------------------------
			" Write line appending the existing file.
			" -----------------------------------------------------------------
			call writefile([g:outline], g:tag_summary_file, "a")
		endif
	endif
endfunction

function! ProcessAnnotations() abort
	" -----------------------------------------------------------------
	" Make sure if its the first annotation line that we
	" have values for last_buffer_name and
	" last_annotation_line_number.
	" -----------------------------------------------------------------
	if (g:annotation_lines_processed == 1)
		" -----------------------------------------------------------------
		" Update last_buffer_name and
		" last_annotation_line_number.
		" -----------------------------------------------------------------
		let g:last_buffer_name = g:current_buffer_name
		let g:last_annotation_line_number = g:current_annotation_line_number
		" -----------------------------------------------------------------
		" Get g:first_row and g:annotation_text
		" from the annotation document.
		" -----------------------------------------------------------------
		call GetInfoFromSearchResultBuffer(g:is_annotation)
		" -----------------------------------------------------------------
		" Write annotation text to the s register
		" -----------------------------------------------------------------
			let @s = @s . "\n-----------------\n\n" . g:annotation_text
		let g:last_write = "annotation"
	endif
	
	" -----------------------------------------------------------------
	" Decide how to process annotation Location List
	" Results.
	" -----------------------------------------------------------------

	" -----------------------------------------------------------------
	" If it comes from the same annotation as the last
	" search result do nothing.
	" -----------------------------------------------------------------

	if (g:last_buffer_name == g:current_buffer_name)
		" --------------------------------------------------------------
		" Do nothing.
		" --------------------------------------------------------------
	" -----------------------------------------------------------------
	" If it is not from the same annotation as the last
	" one.
	" -----------------------------------------------------------------
	elseif (g:last_buffer_name != g:current_buffer_name)
		" -----------------------------------------------------------------
		" Update last_buffer_name and
		" last_annotation_line_number.
		" -----------------------------------------------------------------
		let g:last_buffer_name = g:current_buffer_name
		let g:last_annotation_line_number = g:current_annotation_line_number
		" -----------------------------------------------------------------
		" Get g:first_row and g:annotation_text
		" from the annotation document.
		" -----------------------------------------------------------------
		call GetInfoFromSearchResultBuffer(g:is_annotation)
		" -----------------------------------------------------------------
		" Write annotation text to the s register
		" -----------------------------------------------------------------
		let @s = @s . "\n-----------------\n\n" . g:annotation_text

		let g:last_write = "annotation"
	endif
endfunction

" -----------------------------------------------------------------
" This builds a formatted report for the tag specified as the search_term
" argument.
" -----------------------------------------------------------------

function! TagReport(search_term) abort
	call SetUpReportVariables(a:search_term)
	" -----------------------------------------------------------------
	" Call VimwikiSearchTags against the a:search_term argument.
	" and open the Location List buffer.
	" -----------------------------------------------------------------
	execute "normal! :VimwikiSearchTags " . a:search_term . "\<CR>"
	execute "normal! :lopen\<CR>"
	" -----------------------------------------------------------------
	" Get the number of search results in the Location List buffer.
	" -----------------------------------------------------------------
	let g:num_search_results = line('$')
	" -----------------------------------------------------------------
	" Initialize values the will be used in the for loop below.
	" -----------------------------------------------------------------
	let g:last_interview_line_number = 0
	let g:current_interview_line_number = 0
	let g:last_annotation_line_number = 0
	let g:current_annotation_line_number = 0
	let g:current_buffer_name = ""
	let g:last_buffer_name = ""
	let g:current_buffer_length = 0
	let g:block_count = 0
	let g:first_row = ""
	let g:interview_lines_processed = 0
	let g:annotation_lines_processed = 0
	let g:last_write = ""
	let @s = ""			" The summary is going to be aggregated in the s register.
	" -----------------------------------------------------------------
	" Go through all the results in the Location List buffer. The cursor
	" should enter the loop the first time in the open Location List on
	" the first result.
	" -----------------------------------------------------------------
	for g:location_list_result_num in range(1, g:num_search_results)
		call FigureOutWhatKindOfSearchResultThisIs()
		" -----------------------------------------------------------------
		" Process interview lines.
		" -----------------------------------------------------------------
		if (g:is_interview == 1)
			" ------------------------------------------------------------
			" Process interview lines but do not remove metadata
			" (No) and do write output lines (Yes).
			" ------------------------------------------------------------
			call ProcessInterviewLines("No", "Yes", a:search_term)
		endif
		" -----------------------------------------------------------------
		" Process annotation lines.
		" -----------------------------------------------------------------
		if (g:is_annotation == 1)
			call ProcessAnnotations()
		endif
		" -----------------------------------------------------------------
		" Make sure we don't try to go beyond the end of the Location list results 
		" on the last iteration of the loop.
		" -----------------------------------------------------------------
		if (g:location_list_result_num < g:num_search_results)
			execute "normal! :lopen\<CR>gg" . g:location_list_result_num . "j"
		endif
	endfor
	" -----------------------------------------------------------------
	" Write report to buffer. Up one window; Go to R mark; Paste s
	" register; add a space under title; Close Location List.
	" -----------------------------------------------------------------
	execute "normal! \<C-w>k" 
	execute "normal! `R"
	execute "normal! \"sp"
	execute "normal! ggo\<ESC>gg"
	execute "normal! :lclose\<CR>"

endfunction

function! GetInfoFromSearchResultBuffer(is_annotation_buffer) abort
	" -----------------------------------------------------------------
	" Go to the Location List result under the cursor.
	" -----------------------------------------------------------------
	execute "normal! \<CR>"
	" -----------------------------------------------------------------
	" Get info depending on whether it is an interview or annotation
	" buffer.
	" -----------------------------------------------------------------
	if (a:is_annotation_buffer == 0)	" FALSE, i.e. its an interview buffer.
		" -----------------------------------------------------------------
		" Get the first line and the length of the buffer in lines.
		" -----------------------------------------------------------------
		execute "normal! ggVy"
		let g:first_row = @@
		let g:current_buffer_length = line('$')
	else 					" it is an annotation buffer
		" -----------------------------------------------------------------
		" Get the first line and copy the annotation text.
		" -----------------------------------------------------------------
		execute "normal! ggVy"
		let g:first_row = @@
		execute "normal! VGy"
		let g:annotation_text = @@
	endif
endfunction

function! UpdateSubcode() abort
	let @@ =""
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1
	" -----------------------------------------------------------------
	" Change the pwd to that of the current wiki.
	" -----------------------------------------------------------------

	" -----------------------------------------------------------------
	" Build the path and file name for the subcode_dictionary output file.
	" -----------------------------------------------------------------
	let g:built_subcode_dictionary_path = "g:wiki_" . g:wiki_number . ".subcode_dictionary"
	let g:subcode_dictionary_path = eval(g:built_subcode_dictionary_path)

	" Process the first case
	" Initialise list
	let g:subcode_list = []

	" VWS to get search results and open location list
	execute "normal! :VWS " . '/ _\w\{1,}/' . "\<CR>"
	execute "normal! :lopen\<CR>"	

	" Add first search result to list
	let g:is_search_result = search(' _\w\{1,}', "W")
	if (g:is_search_result != 0)
		execute "normal! lviwyel"
		let g:subcode_list = g:subcode_list + [@@]	
		while (g:is_search_result != 0)
			let g:is_search_result = search(' _\w\{1,}', "W")
			if (g:is_search_result != 0)
				execute "normal! lviwyel"
				let g:subcode_list = g:subcode_list + [@@]
			endif 
		endwhile
	endif

	" -----------------------------------------------------------------
	" Need to change the list to a string so it can be pasted into a
	" buffer.
	" -----------------------------------------------------------------

	let g:subcode_list_as_string = string(g:subcode_list)
	
	" -----------------------------------------------------------------
	" Open new buffer; delete its contents and replace them with
	" g:subcode_list_as_a_string; sort the buffer keeping unique values
	" and delete the top line which is a blank line; save the file writing
	" over top of what's there (!); close the Location List and close the
	" 'new' buffer without saving. (You saved the content of this buffer
	" to a file.
	" -----------------------------------------------------------------

	execute "normal! :sp new\<CR>"
	execute "normal! ggVGd:put=" . g:subcode_list_as_string . "\<CR>"
	execute "normal! :sort u\<CR>dd"
	execute "normal! :w! "  . g:subcode_dictionary_path . "\<CR>"
	execute "normal! \<C-w>k:lclose\<CR>\<C-w>j:q!\<CR>"
endfunction


function! GlossaryDef() abort

	" -----------------------------------------------------------------
	" Initialise variables 
	" -----------------------------------------------------------------

	let @@ =""
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1

	" -----------------------------------------------------------------
	" Build pathname to glossary page
	" -----------------------------------------------------------------

	let g:built_glossary_path = "g:wiki_" . g:wiki_number . ".glossary"
	let g:glossary_path = eval(g:built_glossary_path)
	let g:built_ext =  "g:wiki_" . g:wiki_number . ".ext"
	let g:ext_path = eval(g:built_ext)

	let g:glossary_path = g:glossary_path . g:ext_path

	" -----------------------------------------------------------------
	" Copy tag name to be searched 
	" -----------------------------------------------------------------
	
	execute "normal! viwy "
	let g:tag_name = @@

	" -----------------------------------------------------------------
	" Build a regex with tag name  
	" -----------------------------------------------------------------

	let g:regex = 'Tag\sName:\s*' . g:tag_name 
	
	" -----------------------------------------------------------------
	" Open vertical split window with path name
	" Search with regex and position result at top of page  
	" -----------------------------------------------------------------

 	execute "normal! :vsp ". g:glossary_path . "\<CR>"  
	execute "normal! :/" . g:regex . "\<CR>"
	execute "normal! z\<CR>"
	
endfunction

" -----------------------------------------------------------------
" This is a batch job that will compare the tags in the current buffer to the
" tags in the .vimwiki_tags file. If the tag isn't in the .vimwiki_tags file
" it will change the tag to uppercase.
" -----------------------------------------------------------------

function! TagLinter() abort
	" -----------------------------------------------------------------
	" Get a list of the tags for this wiki
	" -----------------------------------------------------------------
	let g:tag_list = vimwiki#tags#get_tags()
	let g:tag_list = sort(uniq(g:tag_list))
	" -----------------------------------------------------------------
	" Go to the top of the buffer. 
	" -----------------------------------------------------------------
	execute "normal! gg"
	" -----------------------------------------------------------------
	" Set tag_found to true. If search() doesn't find a match it returns a 0
	" which conveniently is also how we represent FALSE. So we go into the while
	" loop with tag_found equal to 1 (TRUE) so that the loop executes at least
	" once.
	" -----------------------------------------------------------------
	let g:tag_found = 1
	while (g:tag_found != 0)
		" -----------------------------------------------------------------
		" Find the next tag in the document. The 'W' argument means
		" stop looking at the bottom of the buffer.
		" -----------------------------------------------------------------
		let g:tag_found = search(':\w\{1,}:', 'W')
		" -----------------------------------------------------------------
		" Set our tag_is_good var to false. ie we assume its not in there until we
		" prove it is.
		" -----------------------------------------------------------------
		let g:tag_is_good = 0
		" -----------------------------------------------------------------
		" If we found a tag with the search() function
		" -----------------------------------------------------------------
		if (g:tag_found != 0)
			" -----------------------------------------------------------------
			" copy the tag we found into @@
			" -----------------------------------------------------------------
			execute "normal! lviwy"
			" -----------------------------------------------------------------
			" Cycle through the tag_list and see if our tag matches any of them. If
			" we find a match change tag_is_good to true and exit the for loop.
			" There's no need to look further.
			" -----------------------------------------------------------------
			for l:tag in range(0, len(g:tag_list) - 1)
				if (g:tag_list[l:tag] == @@)  
					let g:tag_is_good = 1
					break
				endif
			endfor
			" -----------------------------------------------------------------
			" If we didn't find a match change the tag to uppercase
			" -----------------------------------------------------------------
			if (g:tag_is_good == 0)
				execute "normal! viwgU"
			endif
		endif
	endwhile
	execute "normal! gg"
endfunction


function! VWSReport(search_term) abort
	call SetUpReportVariables(a:search_term)
	" -----------------------------------------------------------------
	" Call VimwikiSearchTags against the a:search_term argument.
	" and open the Location List buffer.
	" -----------------------------------------------------------------
	let g:escaped_search_term = escape(a:search_term, ' \')
	execute "normal! :VimwikiSearch /" . a:search_term . "/\<CR>"
	execute "normal! :lopen\<CR>"
	" -----------------------------------------------------------------
	" Get the number of search results in the Location List buffer.
	" -----------------------------------------------------------------
	let g:num_search_results = line('$')
	" -----------------------------------------------------------------
	" Initialize values the will be used in the for loop below.
	" -----------------------------------------------------------------
	let g:last_interview_line_number = 0
	let g:current_interview_line_number = 0
	let g:last_annotation_line_number = 0
	let g:current_annotation_line_number = 0
	let g:current_buffer_name = ""
	let g:last_buffer_name = ""
	let g:current_buffer_length = 0
	let g:block_count = 0
	let g:first_row = ""
	let g:interview_lines_processed = 0
	let g:annotation_lines_processed = 0
	let g:last_write = ""
	let @s = ""			" The summary is going to be aggregated in the s register.
	" -----------------------------------------------------------------
	" Go through all the results in the Location List buffer. The cursor
	" should enter the loop the first time in the open Location List on
	" the first result.
	" -----------------------------------------------------------------
	for g:location_list_result_num in range(1, g:num_search_results)
		call FigureOutWhatKindOfSearchResultThisIs()
		" -----------------------------------------------------------------
		" Process interview lines.
		" -----------------------------------------------------------------
		if (g:is_interview == 1)
			" ------------------------------------------------------------
			" Process interview lines but do not remove metadata
			" (No) and do not write output lines (No).
			" ------------------------------------------------------------
			call ProcessInterviewLines("No", "No", a:search_term)
		endif
		" -----------------------------------------------------------------
		" Process annotation lines.
		" -----------------------------------------------------------------
		if (g:is_annotation == 1)
			call ProcessAnnotations()
		endif
		" -----------------------------------------------------------------
		" Make sure we don't try to go beyond the end of the Location list results 
		" on the last iteration of the loop.
		" -----------------------------------------------------------------
		if (g:location_list_result_num < g:num_search_results)
			execute "normal! :lopen\<CR>gg" . g:location_list_result_num . "j"
		endif
	endfor
	" -----------------------------------------------------------------
	" Write report to buffer. Up one window; Go to R mark; Paste s
	" register; add a space under title; Close Location List.
	" -----------------------------------------------------------------
	execute "normal! \<C-w>k" 
	execute "normal! `R"
	execute "normal! \"sp"
	execute "normal! ggo\<ESC>gg"
	execute "normal! :lclose\<CR>"
endfunction

function! TagFillWithChoice() abort
	" ---------------------------------------------
	" Create an empty matched-tag-list
	" ---------------------------------------------
	let g:matched_tag_list = []
	" ---------------------------------------------
	" Set tag fill mode
	" ---------------------------------------------
	if !exists("g:tag_fill_option") 
		let g:tag_fill_option = "last tag added"
	endif
	" ------------------------------------------------------------
	" Find the last tag entered on the page. Do this by putting
	" :changes into a register c and then searching it for the
	" first tag. Then make the last tag added the default tag in
	" the matched_tag_list.
	" ------------------------------------------------------------
	if (g:tag_fill_option == "last tag added")
		" ------------------------------------------------------------
		"  Redirect output to register changes variable
		" ------------------------------------------------------------
		set nomore
		redir => g:changes
		changes
		redir END
		set more
		" ------------------------------------------------------------
		" Redraw to get past the "press Enter" message that the
		" changes command produces
		" ------------------------------------------------------------
		redraw!
		" ------------------------------------------------------------
		" Find the last tag in changes variable. Note the regex here
		" finds a tag that isn't followed by a tag. I think this is
		" called a negative lookahead. First you need to take out the
		" line breaks in what is sent to the changes variable register.
		" ------------------------------------------------------------
		let g:changes = substitute(g:changes, '\n', '', "g")

		let g:most_recent_tag_in_changes = ""
		let g:is_tag_on_page = 0
		let g:most_recent_tag_in_changes_start = match(g:changes, ':\a\w\{1,}:\(.*:\a\w\{1,}:\)\@!')
		" ------------------------------------------------------------
		" If there is a tag on the page, find what it is.
		" ------------------------------------------------------------
		if g:most_recent_tag_in_changes_start != -1
			let g:most_recent_tag_in_changes_end = match(g:changes, ':', g:most_recent_tag_in_changes_start + 1)
			let g:most_recent_tag_in_changes = g:changes[(g:most_recent_tag_in_changes_start + 1):(g:most_recent_tag_in_changes_end - 1)]
			let g:is_tag_on_page = 1
		endif
		" ------------------------------------------------------------
		" Next we have to take g:most_recent_tag_in_changes and make it the
		" first tag in matched_tag_list. We'll also have to make sure
		" that it doesn't appear in matched tag list twice.
		" ------------------------------------------------------------
		if g:is_tag_on_page == 1
			let g:matched_tag_list = [g:most_recent_tag_in_changes] 
		endif
	endif
	" ----------------------------------------------------
	" Mark the line and column number where you want the bottom of the 
	" tag block to be.
	" -----------------------------------------------------
	let g:bottom_line = line('.')
	let g:bottom_col = virtcol('.')
	" -----------------------------------------------------
	" Find tags in lines above and add them to a list until
	" the there is a gap between the lines with tags
	" -----------------------------------------------------
	" -----------------------------------------------------
	" Search for first match
	" -----------------------------------------------------
	let g:match_line = search(':\a\w\{1,}:', 'b')
	" -----------------------------------------------------
	"  As long as we found a match (ie the result of the search function
	"  is not equal to zero) continue.
	"  ----------------------------------------------------
	if (g:match_line == 0)
		echom("No tags found")
	else
		" ----------------------------------------------
		" Set the last-matched-line equal to the matched-line. This is
		" the first case situation.
		" ----------------------------------------------
		let g:last_match_line = g:match_line
		" ----------------------------------------------
		" Copy the first found tag and add it to the matched-tag-list.
		" Note the hh at the end of the execute statment moves the
		" cursor to the left of the tag we just matched. This is so it
		" doesn't get selected again when we look for more tags.
		" ----------------------------------------------
		execute "normal! lviwyhh"
		let g:first_tag_in_block = [@@]
		if (g:tag_fill_option == "last tag added") && (g:first_tag_in_block[0] != g:matched_tag_list[0])
			let g:matched_tag_list = g:matched_tag_list + g:first_tag_in_block
		else
			let g:matched_tag_list = g:first_tag_in_block
		endif
		" -----------------------------------------------------------
		" Set an is-contiguous-tag-block boolean function to true (1).
		" -----------------------------------------------------------
		let g:is_contiguous_tagged_block = 1
		" ----------------------------------------------------------
		" Now we're going to look for the rest of the tags in a
		" contiguously tagged block above where the cursor is.
		" ----------------------------------------------------------
		while (g:is_contiguous_tagged_block == 1)
			" --------------------------------------------------
			" Search backwards ('b') for another tag.
			" --------------------------------------------------
			let g:match_line = search(':\a\w\{1,}:', 'b')
			" --------------------------------------------------
			" If we found a tag (ie. The search function doesn't
			" return a zero) decide if we need to add it to our
			" list.
			" --------------------------------------------------
			if (g:match_line != 0)
				" -------------------------------------------
				" Copy the tag we found. 
				" -------------------------------------------
				execute "normal! lviwyhh"
				let g:this_tag = @@
				" -------------------------------------------
				" We're setting up the have-tag variable as a
				" boolean. So have-tag is set to 0 or false.
				" -------------------------------------------
				let g:have_tag = 0
				" -------------------------------------------
				" Test to see if we already have this tag in
				" our list. If we don't then add it to our tag
				" list. This next if block will only run if
				" the most recently found tag is no more than
				" one line above the previously found tag.
				" -------------------------------------------
				if (g:last_match_line - g:match_line <= 1)
					" -----------------------------------
					"  Search through the matched-tag-list
					"  to see if we already have the tag
					"  we're considering on this iteration
					"  of the while loop
					"  ----------------------------------
					for l:tag in g:matched_tag_list
						if (l:tag == g:this_tag)
							let g:have_tag = 1
						endif
					endfor
					" -----------------------------------
					" If have tag is still false then
					" we'll add it to our match-tag-list.
					" Note we're not sorting our list.
					" This means that the tags will be in
					" the order they are found as we
					" search backwards.
					" -----------------------------------
					if (g:have_tag == 0)
						let g:matched_tag_list = g:matched_tag_list + [g:this_tag]
					endif
					" -----------------------------------
					" Before we iterate again we have to
					" make the last-match-line equal to
					" our current match-line.
					" ----------------------------------
					let g:last_match_line = g:match_line
				else
					" -----------------------------------
					" If the most recently found tag is on
					" a line more than one line above the
					" previously found tag then we found a
					" tag outside of the tag block.
					" -----------------------------------
					let g:is_contiguous_tagged_block = 0
				endif
			endif 
		endwhile	
		
		" ------------------------------------------------------------
		" The choice number is the matched tag list index number. So 0
		" is the first element in the list. This will be the first tag
		" we found when we searched backwards. 
		" ------------------------------------------------------------
		let g:choice = 0
		" ------------------------------------------------------------
		"  If the list has more than one element you want the user to
		"  choose the proper tag. Hitting enter chooses the first item
		"  in the list.
		" ------------------------------------------------------------
		if (len(g:matched_tag_list) > 1)
			" ----------------------------------------------------
			" We have to take the matched-tag-list and format it
			" for the confirm function. Each choice has to be
			" preceeded by an & and followed by a \n. 
			" ----------------------------------------------------
			let g:choice_list = ""
			for l:choice in range(0, len(g:matched_tag_list) - 1)
				let g:choice_list = g:choice_list . "&" . g:matched_tag_list[l:choice] . "\n"
			endfor
			" ----------------------------------------------------
			" This next line takes off the last \n
			" ----------------------------------------------------
			let g:choice_list = g:choice_list[:-2]
			" ----------------------------------------------------
			" The third argument in the confirm function is the
			" default choice. In this case, 1 for the first item.
			" Because we're choosing from a list we need to reduce
			" the choice number by one since lists start counting
			" at zero.
			" ----------------------------------------------------
			let g:choice = confirm("Choose Tag: ", g:choice_list, 1)
			let g:choice = g:choice - 1
		endif
		" ------------------------------------------------------------
		" Now we have our choice which corresponds to the matched-tag-
		" list element. All that remains is to fill the tag.
		" ------------------------------------------------------------
		let g:tag_to_fill = ":" . g:matched_tag_list[g:choice] . ":"
		" ------------------------------------------------------------
		" Now we have to find the range to fill
		" ------------------------------------------------------------
		call cursor(g:bottom_line, g:bottom_col)
		let g:line_of_tag_to_fill = search(g:tag_to_fill, 'bW')
		" ------------------------------------------------------------
		" If the tag_to_fill is found above the cursor position, and
		" its not more than 20 lines above the contiguously tagged
		" block above the cursor position.
		" ------------------------------------------------------------
		let g:proceed_to_fill = 0
		if (g:tag_fill_option == "bottom of contiguous block")
			let g:proceed_to_fill = 1
			let g:lines_to_fill = g:bottom_line - g:line_of_tag_to_fill
		elseif (g:line_of_tag_to_fill != 0)
			"execute "normal! ?" . g:tag_to_fill . "\<CR>"
			let g:lines_to_fill = g:bottom_line - g:line_of_tag_to_fill
			let g:proceed_to_fill = 1
		endif
		" ------------------------------------------------------------
		" This actually fills the tag.
		" ------------------------------------------------------------
		call cursor(g:bottom_line, g:bottom_col)
		if (g:proceed_to_fill)
			execute "normal! V" . g:lines_to_fill . "k\<CR>:s/$/ " . g:tag_to_fill . "/\<CR>"
		else
			echom "Tag not found. No action taken."
		endif

	endif	
endfunction

function! ChangeTagFillOption() abort
	if (!exists("g:tag_fill_option"))
		let g:tag_fill_option = "last tag added"
		echom "Default tag presented when F5 is pressed will be the last tag added to the buffer."
	elseif (g:tag_fill_option == "last tag added")
		let g:tag_fill_option = "bottom of contiguous block"
		echom "Default tag presented when F5 is pressed will be the last tag in the contiguous block above the cursor."
	else
		let g:tag_fill_option = "last tag added"
		echom "Default tag presented when F5 is pressed will be the last tag added to the buffer."
	endif
endfunction

function! JustQuotes(search_term) abort
	call SetUpReportVariables(a:search_term)
	" -----------------------------------------------------------------
	" Call VimwikiSearchTags against the a:search_term argument.
	" and open the Location List buffer.
	" -----------------------------------------------------------------
	execute "normal! :VimwikiSearchTags " . a:search_term . "\<CR>"
	execute "normal! :lopen\<CR>"
	" -----------------------------------------------------------------
	" Get the number of search results in the Location List buffer.
	" -----------------------------------------------------------------
	let g:num_search_results = line('$')
	" -----------------------------------------------------------------
	" Initialize values the will be used in the for loop below.
	" -----------------------------------------------------------------
	let g:last_interview_line_number = 0
	let g:current_interview_line_number = 0
	let g:last_annotation_line_number = 0
	let g:current_annotation_line_number = 0
	let g:current_buffer_name = ""
	let g:last_buffer_name = ""
	let g:current_buffer_length = 0
	let g:block_count = 0
	let g:first_row = ""
	let g:interview_lines_processed = 0
	let g:annotation_lines_processed = 0
	let g:last_write = ""
	let @s = ""			" The summary is going to be aggregated in the s register.
	" -----------------------------------------------------------------
	" Go through all the results in the Location List buffer. The cursor
	" should enter the loop the first time in the open Location List on
	" the first result.
	" -----------------------------------------------------------------
	for g:location_list_result_num in range(1, g:num_search_results)
		call FigureOutWhatKindOfSearchResultThisIs()
		" -----------------------------------------------------------------
		" Process interview lines.
		" -----------------------------------------------------------------
		if (g:is_interview == 1)
			" ------------------------------------------------------------
			" Process interview lines and remove metadata (Yes)
			" but do not write output records (No)
			" ------------------------------------------------------------
			call ProcessInterviewLines("Yes", "No", a:search_term)
		endif
		" -----------------------------------------------------------------
		" Make sure we don't try to go beyond the end of the Location list results 
		" on the last iteration of the loop.
		" -----------------------------------------------------------------
		if (g:location_list_result_num < g:num_search_results)
			execute "normal! :lopen\<CR>gg" . g:location_list_result_num . "j"
		endif
		" -----------------------------------------------------------------
		" Write last quote label
		" -----------------------------------------------------------------
		if (g:location_list_result_num == g:num_search_results)
			let @s = @s . " " . g:current_buffer_name . " " . g:current_interview_line_number 
		endif
	endfor
	" -----------------------------------------------------------------
	" Write report to buffer. Up one window; Go to R mark; Paste s
	" register; add a space under title; Close Location List.
	" -----------------------------------------------------------------
	execute "normal! \<C-w>k" 
	execute "normal! `R"
	" ------------------------------------------------------
	" Remove extra whitespace
	" ------------------------------------------------------
	let @s = substitute(@s, '\s\+', ' ', "g")
	let @s = substitute(@s, '(\d:\d\d:\d\d)\sspk_\d:\s', '', "g")
	" ------------------------------------------------------
	" Paste the s register into the buffer. The s register has the quotes
	" we've been copying.
	" ------------------------------------------------------
	execute "normal! \"sp"
	execute "normal! ggo\<ESC>gg"
	execute "normal! :lclose\<CR>"
endfunction

" ------------------------------------------------------
"
" ------------------------------------------------------
function! CheckForTagListOmniCompleteTag() abort
	" -----------------------------------------------------------------
	" Change the pwd to that of the current wiki.
	" -----------------------------------------------------------------
	execute "normal! :cd %:p:h\<CR>"
	" ------------------------------------------------------
	" Find the vimwiki that the current buffer is in.
	" ------------------------------------------------------
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1
	let g:built_current_wiki = "g:wiki_" . g:wiki_number
	" ------------------------------------------------------
	" See if the wiki config dictionary has had a
	" tags_generated_this_session key added.
	" ------------------------------------------------------
	let g:tags_have_been_generated_for_this_wiki_this_session = has_key(eval(g:built_current_wiki), 'tags_generated_this_session')
	" ------------------------------------------------------
	" Checks to see if we have the proper currrent tag list for our tag
	" omnicompletion.
	" ------------------------------------------------------
	if !exists("g:current_tags_set_this_session")
		call NoTagListNotice(1)
	else
		if g:tags_have_been_generated_for_this_wiki_this_session != 1 
			call NoTagListNotice(2)
		else
			if g:last_wiki_tags_generated_for != g:wiki_number
				call NoTagListNotice(3)
			else
				" ------------------------------------------------------
				" The ! after startinsert makes it insert after (like A). If
				" you don't have the ! it inserts before (like i)
				" ------------------------------------------------------
				startinsert!
				call feedkeys("\<c-x>\<c-o>")
			endif
		endif
	endif
endfunction

function! GetTagUpdate() abort
	call confirm("Populating tags. This may take a while.", "Got it", 1)
	call CreateTagDict()
	" -----------------------------------------------------------------
	" Change the pwd to that of the current wiki.
	" -----------------------------------------------------------------
	execute "normal! :cd %:p:h\<CR>"
	" ------------------------------------------------------
	" Find the vimwiki that the current buffer is in.
	" ------------------------------------------------------
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1
	" -----------------------------------------------------------------
	" Save the current buffer so any new tags are found by
	" VimwikiRebuildTags
	" -----------------------------------------------------------------
	execute "normal :w\<CR>"
	call vimwiki#tags#update_tags(1, '<bang>')
	" -----------------------------------------------------------------
	" g:current_tags is used in vimwiki's omnicomplete function. At this
	" point this is a modifcation to ftplugin#vimwikimwiki#Complete_wikifiles
	" where
	"    let tags = vimwiki#tags#get_tags()
	" has been replaced by
	"    let tags = deepcopy(g:current_tags)
	" This was done because as the number of tags grows in a project
	" vimwiki#tags#get_tags() slows down.
	" -----------------------------------------------------------------
	let g:current_tags = vimwiki#tags#get_tags()
	let g:current_tags = sort(g:current_tags, 'i')
	" ------------------------------------------------------
	" Add an element to the current wiki's configuration dictionary that
	" marks it as having had its tags generated in this vim session.
	" ------------------------------------------------------
	execute ":let g:wiki_" . g:wiki_number . "['tags_generated_this_session']=1"
	" ------------------------------------------------------
	" Set the current wiki as the wiki that g:current_tags were last
	" generated for. Also mark that a set of current tags has been
	" generated to true.
	" ------------------------------------------------------
	let g:last_wiki_tags_generated_for = g:wiki_number
	let g:current_tags_set_this_session = 1
	" ------------------------------------------------------
	" Popup menu to display the list of current tags sorted in
	" case-insenstive alphabetical order
	" ------------------------------------------------------
	call GenDictTagList()
	call CurrentTagsPopUpMenu()
endfunction

function! GenDictTagList() abort
	let g:dict_tags = []
	for l:tag_index in range(0, (len(g:current_tags)-1))
 		if has_key(g:tag_dict, g:current_tags[l:tag_index])
			let g:dict_tags = g:dict_tags + [g:current_tags[l:tag_index]]
		endif
	endfor
endfunction

function! CurrentTagsPopUpMenu() abort
	call popup_menu(g:current_tags , 
				\ #{ minwidth: 50,
				\ maxwidth: 50,
				\ pos: 'center',
				\ border: [],
				\ close: 'click',
				\ })
endfunction

function! NoTagListNotice(tag_message) abort
	if (a:tag_message == 1)
		let s:popup_message = "Press <F2> to populate the current tag list."
	elseif (a:tag_message == 2)
		let s:popup_message = "A tag list for this wiki has not been generated yet this session. Press <F2> to populate the current tag list with this wiki\'s tags."
	else 
		let s:popup_message = "Update the tag list with this wiki\'s tags by pressing <F2>."
	endif
	call confirm(s:popup_message, "Got it", 1)
endfunction

function! SortTagDefs() abort
	execute "normal! :%s/}/}\\r/g\<CR>"
	execute "normal! :g/{/,/}/s/\\n/TTT\<CR>"
	execute "normal! :3,$sort \i\<CR>"
	execute "normal!" .':3,$g/^$/d' . "\<CR>"
	execute "normal! :%s/TTT/\\r/g\<CR>"
endfunction

function! TrimLeadingPartialSentence() abort
	execute "normal! vip\"by"
	execute "normal! `<v)hx"
endfunction

function! TrimTrailingPartialSentence() abort
	execute "normal! vip\"by"
	execute "normal! `>(v)di\r\r\<ESC>kk"
endfunction


function! Attributes() abort
	" -----------------------------------------------------------------
	" Change the pwd to that of the current wiki.
	" -----------------------------------------------------------------
	execute "normal! :cd %:p:h\<CR>"
	" -----------------------------------------------------------------
	" Find the wiki we're in and get its wiki number.
	" We have to add 1 because Vimwiki counts its wikis within a list and
	" lists are indexed starting at zero. However when we make our wiki numbers
	" in our .vimrc we start at 1.
	" -----------------------------------------------------------------
	let g:wiki_number = vimwiki#vars#get_bufferlocal('wiki_nr') + 1
	" -----------------------------------------------------------------
	" Get this wiki's interview label regex and file extension.
	" -----------------------------------------------------------------
	let g:built_interview_label_var_name = "g:wiki_" . g:wiki_number . ".interview_label_regex"
	let g:interview_label_regex = eval(g:built_interview_label_var_name)
	let g:built_file_extension = "g:wiki_" . g:wiki_number . ".ext"
	let g:current_wiki_extension = eval(g:built_file_extension)
	" -----------------------------------------------------------------
	" Get a list of all the files and directories in the pwd. Note the
	" fourth argument that is 1 makes it return a list. The first argument
	" '.' means the current directory and the second argument '*' means
	" all.
	" ----------------------------------------------------------------
	let g:file_list_all = globpath('.', '*', 0, 1)
	" -----------------------------------------------------------------
	" Build regex we'll use just to find our interview files. 
	" -----------------------------------------------------------------
	let g:file_regex = g:interview_label_regex . '.md'
	" -----------------------------------------------------------------
	"  Cull the list for just those files that are interview files. The
	"  match is at position 2 because the globpath function prefixes
	"  filenames with ./ which occupies positions 0 and 1.
	" -----------------------------------------------------------------
	let g:interview_list = []
	for list_item in range(0, (len(g:file_list_all)-1))
		if (match(g:file_list_all[list_item], g:file_regex) == 2) 
			" -----------------------------------------------------------------
			" Strip off the leading ./
			" -----------------------------------------------------------------
			let g:file_to_add = g:file_list_all[list_item][2:]
			let g:interview_list = g:interview_list + [g:file_to_add]
		endif
	endfor
	" -----------------------------------------------------------------
	" Save buffer number of current file to register 'a' so you can return here
	" -----------------------------------------------------------------
	let @a = bufnr('%')
	" -----------------------------------------------------------------
	" Go through the list of files copying and processing the first line
	" from the buffer which should be the line of the interview attribute
	" tags. We're going to build our output in two reg
	" -----------------------------------------------------------------
	let g:attrib_chart = ""
	let g:attrib_csv   = ""
	for interview in range(0, (len(g:interview_list)-1))
		" -----------------------------------------------------------------
		" Go to interview file
		" -----------------------------------------------------------------
		execute "normal :e " . g:interview_list[interview] . "\<CR>"
		" -----------------------------------------------------------------
		" Copy first row which should be the attribute tags.
		" -----------------------------------------------------------------
		execute "normal! ggVy"
		let g:first_row = @@
		" -----------------------------------------------------------------
		" Format the attribute tags for the chart and for the csv
		" -----------------------------------------------------------------
		let g:attrib_chart_line = substitute(g:first_row, ":", "|", "g")
		let g:attrib_chart_line = "|" . g:interview_list[interview] . g:attrib_chart_line
		let g:attrib_csv_line   = substitute(g:first_row, ":", ",", "g")
		let g:attrib_csv_line   = g:interview_list[interview] . g:attrib_csv_line
		" -----------------------------------------------------------------
		" Add new lines to the chart and csv
		" -----------------------------------------------------------------
		let g:attrib_chart = g:attrib_chart . g:attrib_chart_line
		let g:attrib_csv   = g:attrib_csv . g:attrib_csv_line . "\n"
	endfor
	" -----------------------------------------------------------------
	" Return to page where you're going to print the chart and paste the
	" chart.
	" -----------------------------------------------------------------
	execute "normal! :b\<C-r>a\<CR>gg"
	put =g:attrib_chart
	execute "normal! A\<ESC>\<CR>gg"
endfunction

function! ColSort(column) abort
	let g:sort_regex = "/\\(.\\{-}\\zs|\\)\\{" . a:column . "}/"
	execute "normal! :sort " . g:sort_regex . "\<CR>"
endfunction

function! HelpMenu() abort
	let g:help_list = ["NAVIGATION", "<leader>gt\t\t\tGo To", "<leader>gb\t\t\tGo Back", "<F7>\t\t\t\tAnnotation Toggle", " ", "CODING\n", "<F2>\t\t\t\tUpdate Tags", "<F8>\t\t\t\tTag Omni-Complete", "<F9>\t\t\t\tTag Omni-Complete", "<F5>\t\t\t\tComplete Tag Block", "<leader>tf\t\t\tTag Fill", " ", "REPORTS", "TagReport(\"<tag>\")\t\tCreate Tag Summary", "JustQuotes(\"<tag>\")\t\tTag Summary without metadata", "VWSReport(\"<string>\")\t\tCreate custom search report", " ", "WORKING WITH REPORTS", "<leader>cv\t\t\tCopy Block Quote", "<leader>th\t\t\tTrim Head", "<leader>tt\t\t\tTrim Tail", "<leader>ta\t\t\tTrim Head and Tail", " ", "APPARATUS", "Attributes()\t\t\tCreate Attribute Table", "ColSort(<column number>)\tSort Attribute Table", "SortTagDefs()\t\t\tSort Tag Definition List", "GlossaryDef()\t\t\tUpdate Glossary", "InterviewFormat(\"<label>\")\tFormat Interview Pages", "<leader>rs\t\t\tResize Windows", "<leader>hp\t\t\tHelp Menu"]
	call popup_menu(g:help_list , 
				\ #{ minwidth: 50,
				\ maxwidth: 100,
				\ pos: 'center',
				\ border: [],
				\ close: 'click',
				\ })
endfunction

function GetTagDef() abort
	" ---------------------------------------------------
	" Get the word under the cursor
	" ---------------------------------------------------
	execute "normal! viwy"
	let l:tag_to_look_up = @@
	" ---------------------------------------------------
	" Check to see if that tag is defined and if it is show the definition 
	" in a popup window at the cursor. If not give an error message in a popup
	" window.
	" ---------------------------------------------------
 	if has_key(g:tag_dict, l:tag_to_look_up)
 		call popup_atcursor(get(g:tag_dict, l:tag_to_look_up), {
 			\ 'border': [],
 			\ 'close' : 'click',
 			\ })
 	else
 		call popup_atcursor("\"" . l:tag_to_look_up . "\" is not defined in the Tag Glossary.", {
 			\ 'border': [],
 			\ 'close' : 'click',
 			\ })
 	endif
endfunction

function! CreateTagDict() abort
	" -----------------------------------------------------------------
	" Change the pwd to that of the current wiki.
	" -----------------------------------------------------------------
	execute "normal! :cd %:p:h\<CR>"
	" -----------------------------------------------------------------
	" Save buffer number of current file to register 'a' so you can return here
	" -----------------------------------------------------------------
	let @a = bufnr('%')
	" -----------------------------------------------------------------
	" Go to the tag glossary
	" -----------------------------------------------------------------
	execute "normal :e Tag Glossary\.md\<CR>"
	execute "normal! gg"
	" -----------------------------------------------------------------
	" Define an empty tag dictionary
	" -----------------------------------------------------------------
	let g:tag_dict = {}
	" -----------------------------------------------------------------
	" Build the tag dictionary. 
	" -----------------------------------------------------------------
	while search('{', "W")
		execute "normal! j$bviwy0"
		let l:tag_key = @@
		let l:tag_def_list = []
		while (getline(".") != "}") && (line(".") <= line("$"))
			let l:tag_def_list = l:tag_def_list + [getline(".")]
			execute "normal! j0"
		endwhile
		"execute "normal! jvi\{y"
		let g:tag_dict[l:tag_key] = l:tag_def_list
	endwhile
	" -----------------------------------------------------------------
	" Return to the buffer you called this function from
	" -----------------------------------------------------------------
	execute "normal! :b\<C-r>a\<CR>"
endfunction

