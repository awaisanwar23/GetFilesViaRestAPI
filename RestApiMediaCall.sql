DECLARE
    l_req utl_http.req;
    l_resp utl_http.resp;
    l_url varchar2(4000) := 'your api url returning media file';
    l_clob clob;
    V_TOKEN VARCHAR2(4000) := 'Bearer ' ;--Bearer Token if any
    l_blob_total blob;
    l_filename varchar2(300) := 'test.pdf'; --file name
    l_file      UTL_FILE.FILE_TYPE;
    l_buffer    RAW(32767);
    l_amount    BINARY_INTEGER := 32767;
    l_pos       INTEGER := 1;
    l_blob_len  INTEGER;
    L_DIR_NAME VARCHAR2(400) := 'TEMP_FILES'; --Database Directory Name
BEGIN
UTL_HTTP.set_wallet(path => 'file:/path/to/wallet', password => 'your_password');
l_req:=utl_http.begin_request(url=>l_url);
utl_http.set_header(r=>l_req,NAME=>'Authorization',VALUE=>V_TOKEN); -- In Case Of authorization
utl_http.set_header(r=>l_req,NAME=>'content-type',VALUE=>'application/pdf'); --change Content-Type accordingly
l_resp:=utl_http.get_response(r=>l_req);
IF(l_resp.status_code<>utl_http.http_ok)THEN
DBMS_OUTPUT.PUT_LINE('Error Occured...');
END IF;
BEGIN
dbms_lob.createtemporary(l_blob_total,FALSE);
LOOP
utl_http.read_line(r=>l_resp,data=>l_clob);
dbms_lob.append(dest_lob=>l_blob_total,src_lob=>utl_raw.cast_to_raw(l_clob));
l_clob:=NULL;
END LOOP;
EXCEPTION
WHEN utl_http.end_of_body THEN
NULL;
END;
utl_http.end_response(l_resp);
BEGIN
  l_blob_len := DBMS_LOB.getlength(l_blob_total);
  l_file := UTL_FILE.fopen(L_DIR_NAME, l_filename,'wb', 32767);
  WHILE l_pos <= l_blob_len LOOP
    DBMS_LOB.read(l_blob_total, l_amount, l_pos, l_buffer);
    UTL_FILE.put_raw(l_file, l_buffer, TRUE);
    l_pos := l_pos + l_amount;
  END LOOP;
  UTL_FILE.fclose(l_file);
EXCEPTION
  WHEN OTHERS THEN
    IF UTL_FILE.is_open(l_file) THEN
      UTL_FILE.fclose(l_file);
    END IF;
    DBMS_OUTPUT.PUT_LINE('Error Occured While Saving File...');
END;
END;