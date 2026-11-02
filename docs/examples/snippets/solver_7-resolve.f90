ids = coupled%find_all(name='{https://example.org/thermal}dt')   ! Clark notation: {namespace}local name
do t=1, coupled%tags_number()
   print '(A)', coupled%name(t)//' -> prefix "'//coupled%prefix(t)//'", local "'//coupled%local_name(t)// &
                '", namespace "'//coupled%namespace(t)//'"'
enddo
