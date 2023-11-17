#include <stdio.h>
#include <stdlib.h>
#include <string>
#include "stplugin.h"
#include <julia.h>

#if SYSTEM==STWIN32
#define strtok_r strtok_s
#define snprintf sprintf_s
#endif

jl_value_t* safe_jl_eval_string(const char* cmd) {
    jl_value_t* ret = jl_eval_string(cmd);
    if (jl_value_t* ex = jl_exception_occurred()) {
        jl_call2(
            jl_get_function(jl_base_module, "showerror"),
            jl_eval_string("_Stata_io"),
            ex
        );
        throw(jl_string_data(jl_eval_string("String(take!(_Stata_io))")));
    }
    return(ret);
}

#if SYSTEM==STWIN32
#if __cplusplus
#define STDLL_int	extern "C" __declspec(dllexport) ST_int
#define STDLL_bool	extern "C" __declspec(dllexport) ST_boolean
#else
#define STDLL_int	extern __declspec(dllexport) ST_int
#define STDLL_bool	extern __declspec(dllexport) ST_boolean
#endif
#else
#if __cplusplus
#define STDLL_int extern "C" ST_int
#define STDLL_bool extern "C" ST_boolean
#else
#define STDLL_int ST_int
#define STDLL_bool ST_boolean
#endif
#endif

// wrappers for Stata interface entry points within this shared library, for Julia to find
STDLL jlSF_vdata(ST_int i, ST_int j, ST_double* z) { return(SF_vdata(i, j, z)); }
STDLL jlSF_vstore(ST_int i, ST_int j, ST_double val) { return(SF_vstore(i, j, val)); }
STDLL jlSF_sdata(ST_int i, ST_int j, char* s) { return(SF_sdata(i, j, s)); }
STDLL jlSF_sstore(ST_int i, ST_int j, char* s) { return(SF_sstore(i, j, s)); }
STDLL_int jlSF_sdatalen(ST_int i, ST_int j) { return(SF_sdatalen(i, j)); }
STDLL jlSF_strldata(ST_int i, ST_int j, char* s, ST_int len) { return(SF_strldata(i, j, s, len)); }
STDLL_bool jlSF_var_is_string(ST_int i) { return(SF_var_is_string(i)); }
STDLL_bool jlSF_var_is_strl(ST_int i) { return(SF_var_is_strl(i)); }
STDLL_bool jlSF_var_is_binary(ST_int i, ST_int j) { return(SF_var_is_binary(i, j)); }
STDLL_int jlSF_nobs(void) { return(SF_nobs()); }
STDLL_int jlSF_nvars(void) { return(SF_nvars()); }
STDLL_int jlSF_nvar(void) { return(SF_nvar()); }
STDLL_bool jlSF_ifobs(ST_int j) { return(SF_ifobs(j)); }
STDLL_int jlSF_in1(void) { return(SF_in1()); }
STDLL_int jlSF_in2(void) { return(SF_in2()); }
STDLL jlSF_mat_el(char* mat, ST_int i, ST_int j, ST_double* z) { return(SF_mat_el(mat, i, j, z)); }
STDLL jlSF_mat_store(char* mat, ST_int i, ST_int j, ST_double val) { return(SF_mat_store(mat, i, j, val)); }
STDLL_int jlSF_col(char* mat) { return(SF_col(mat)); }
STDLL_int jlSF_row(char* mat) { return(SF_row(mat)); }
STDLL jlSF_macro_save(char* mac, char* tosave) { return(SF_macro_save(mac, tosave)); }
STDLL jlSF_macro_use(char* mac, char* contents, ST_int maxlen) { return(SF_macro_use(mac, contents, maxlen)); }
STDLL jlSF_scal_save(char* scal, double val) { return(SF_scal_save(scal, val)); }
STDLL jlSF_scal_use(char* scal, double* z) { return(SF_scal_use(scal, z)); }
STDLL jlSF_display(char* s) { return(SF_display(s)); }
STDLL jlSF_error(char* s) { return(SF_error(s)); }
STDLL_bool jlSF_is_missing(ST_double z) { return(SF_is_missing(z)); }


STDLL stata_call(int argc, char *argv[])
{
#define BUFLEN 1000
    char buf[BUFLEN];

    if (!argc) return(0);

    try {
        // argv[0] = "start": initiate Julia instance
        if (!strcmp(argv[0], "start")) {
            jl_init();
            safe_jl_eval_string("const _Stata_io = IOBuffer(); const _Stata_context=IOContext(_Stata_io, :limit=>true)");
            return(0);
        }

        // argv[0] = "stop": terminate Julia instance
        if (!strcmp(argv[0], "stop")) {
            jl_atexit_hook(0);
            return(0);
        }

        // argv[0] = "eval": evaluate a Julia expression and return plaintext response in Stata local "ans"; slow if the return value is, e.g., a large array
        // argv[1] = expression
        if (!strcmp(argv[0], "eval")) {
            if (argc > 1) {
                size_t len = sizeof(char) * (strlen(argv[1]) + 200);
                char* evalbuf = (char*)malloc(len);
                snprintf(evalbuf, len, (char*)"show(_Stata_context, MIME\"text/plain\"(), begin %s end); String(take!(_Stata_io))", argv[1]);
                SF_macro_save((char*)"_ans", (char*)jl_string_data(safe_jl_eval_string(evalbuf)));
            }
            return(0);
        }

        // argv[0] = "eval": evaluate a Julia expression but for speed return no response
        // argv[1] = expression
        if (!strcmp(argv[0], "evalqui")) {
            if (argc > 1) {
                size_t len = sizeof(char) * (strlen(argv[1]) + 70);
                char* evalbuf = (char*)malloc(len);
                snprintf(evalbuf, len, (char*)"begin %s; 0 end", argv[1]);
                safe_jl_eval_string(evalbuf);
            }
            return(0);
        }

        // argv[0] = "PutVarsToDF": put vars in a new, all-Float64 Julia DataFrame, converting Stata missings to NaN (not to Julia missing)
        // argv[1] = DataFrame name; any existing DataFrame of that name will be overwritten
        // argv[2] = name of Stata macro (beginning with "_" if a local) with names for DataFrame cols
        // argv[3] = string rendering of length of that macro
        if (!strcmp(argv[0], "PutVarsToDF")) {
            ST_int nobs = 0;
            char* touse = (char*)malloc(SF_in2() - SF_in1() + 1);
            char* tousej = touse;
            for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                nobs += (*tousej++ = (char)SF_ifobs(j));

            snprintf(buf, BUFLEN, "X = Matrix{Float64}(undef, %i, %i); %s = DataFrame(X, :auto, copycols=false); X", nobs, SF_nvars(), argv[1]);
            jl_value_t* X = safe_jl_eval_string(buf);
            double* px = (double*)jl_array_data(X);

            double NaN = jl_unbox_float64(safe_jl_eval_string("NaN"));

            char* next_token;
            ST_int maxlen = atoi(argv[3]) + 1;
            char* contents = (char*)malloc(maxlen);
            (void)SF_macro_use(argv[2], contents, maxlen);
            char* token = strtok_r(contents, " ", &next_token);

            for (ST_int i = 1; i <= SF_nvars(); i++) {
                tousej = touse;
                for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                    if (*tousej++) {
                        SF_vdata(i, j, px);
                        if (SF_is_missing((ST_double)*px))
                            *px = NaN;
                        px++;
                    }
                if (token != NULL) {
                    snprintf(buf, BUFLEN, "rename!(%s, :x%i => :%s)", argv[1], i, token);
                    (void)safe_jl_eval_string(buf);
                    token = strtok_r(NULL, " ", &next_token);
                }
            }
            return(0);
        }

        // argv[0] = "PutVarsToMat": put vars in a new Julia Matrix{Float64}, converting Stata missings to NaN (not Julia missing)
        // argv[1] = Julia matrix name; any existing matrix of that name will be overwritten
        if (!strcmp(argv[0], "PutVarsToMat")) {
            ST_int nobs = 0;
            char* touse = (char*)malloc(SF_in2() - SF_in1() + 1);
            char* tousej = touse;
            for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                nobs += (*tousej++ = (char)SF_ifobs(j));

            snprintf(buf, BUFLEN, "%s = Matrix{Float64}(undef, %i, %i)", argv[1], nobs, SF_nvars());
            jl_value_t* X = safe_jl_eval_string(buf);
            double* px = (double*)jl_array_data(X);

            double NaN = jl_unbox_float64(safe_jl_eval_string("NaN"));
            for (ST_int i = 1; i <= SF_nvars(); i++) {
                tousej = touse;
                for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                    if (*tousej++) {
                        SF_vdata(i, j, px);
                        if (SF_is_missing((ST_double)*px))
                            *px = NaN;
                        px++;
                    }
            }
            return(0);
        }

        // argv[0] = "PutVarsToDFNoMissing": put vars in a new, all-Float64 Julia DataFrame, with no special handling of Stata missings
        // argv[1] = DataFrame name; any existing DataFrame of that name will be overwritten
        // argv[2] = name of Stata macro (beginning with "_" if a local) with names for DataFrame cols
        // argv[3] = string rendering of length of that macro
        if (!strcmp(argv[0], "PutVarsToDFNoMissing")) {
            ST_int nobs = 0;
            char* touse = (char*)malloc(SF_in2() - SF_in1() + 1);
            char* tousej = touse;
            for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                nobs += (*tousej++ = (char) SF_ifobs(j));

            snprintf(buf, BUFLEN, "X = Matrix{Float64}(undef, %i, %i); %s = DataFrame(X, :auto, copycols=false); X", nobs, SF_nvars(), argv[1]);
            jl_value_t* X = safe_jl_eval_string(buf);
            double* px = (double*)jl_array_data(X);

            char* next_token;
            ST_int maxlen = atoi(argv[3]) + 1;
            char* contents = (char*)malloc(maxlen);
            (void)SF_macro_use(argv[2], contents, maxlen);
            char* token = strtok_r(contents, " ", &next_token);

            for (ST_int i = 1; i <= SF_nvars(); i++) {
                tousej = touse;
                for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                    if (*tousej++)
                        SF_vdata(i, j, px++);
                if (token != NULL) {
                    snprintf(buf, BUFLEN, "rename!(%s, :x%i => :%s)", argv[1], i, token);
                    (void)safe_jl_eval_string(buf);
                    token = strtok_r(NULL, " ", &next_token);
                }
            }
            return(0);
        }

        // argv[0] = "PutVarsToMatNoMissing": put vars in a new Julia Matrix{Float64}, with no special handling of Stata missings
        // argv[1] = Julia matrix name; any existing matrix of that name will be overwritten
        if (!strcmp(argv[0], "PutVarsToMatNoMissing")) {
            ST_int nobs = 0;
            char* touse = (char*)malloc(SF_in2() - SF_in1() + 1);
            char* tousej = touse;
            for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                nobs += (*tousej++ = (char)SF_ifobs(j));

            snprintf(buf, BUFLEN, "%s = Matrix{Float64}(undef, %i, %i)", argv[1], nobs, SF_nvars());
            jl_value_t* X = safe_jl_eval_string(buf);
            double* px = (double*)jl_array_data(X);
            for (ST_int i = 1; i <= SF_nvars(); i++) {
                tousej = touse;
                for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                    if (*tousej++)
                        SF_vdata(i, j, px++);
            }
            return(0);
        }

        // argv[0] = "GetVarsFromDFNoMissing": copy from Julia DataFrame into existing Stata vars, with no special handling of Julia missings; but Julia NaN mapped to Stata missing
        // argv[1] = DataFrame name
        // argv[2] = name of Stata macro (beginning with "_" if a local) with names of DataFrame cols
        // argv[3] = string rendering of length of that macro
        if (!strcmp(argv[0], "GetVarsFromDFNoMissing")) {
            snprintf(buf, BUFLEN, "size(%s,1)", argv[1]);
            size_t nobs = (size_t)jl_unbox_int64(safe_jl_eval_string(buf));

            char* touse = (char*)malloc(SF_in2() - SF_in1() + 1);
            char* tousej = touse;
            for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                *tousej++ = (char)SF_ifobs(j);

            char* next_token;
            ST_int maxlen = atoi(argv[3]) + 1;
            char* contents = (char*)malloc(maxlen);
            (void)SF_macro_use(argv[2], contents, maxlen);
            char* token = strtok_r(contents, " ", &next_token);

            for (ST_int i = 1; i <= SF_nvars(); i++)
                if (token != NULL) {
                    snprintf(buf, BUFLEN, "let x=parent((%s)[!,:%s]); eltype(x)==Float64 ? x : Array{Float64, ndims(x)}(x) end", argv[1], token);  // assure source matrix is double
                    jl_value_t* X = safe_jl_eval_string(buf);
                    double* maxpx = (double*)jl_array_data(X);
                    snprintf(buf, BUFLEN, "let t=parentindices((%s)[!,:%s]); length(t)==1 ? 1 : t[2] end", argv[1], token);
                    maxpx += nobs * jl_unbox_int64(safe_jl_eval_string(buf));
                    double* px = maxpx - nobs;  // start of column of interest in data matrix
                    tousej = touse;
                    for (ST_int j = SF_in1(); j <= SF_in2() && px < maxpx; j++) {
                        if (*tousej++)
                            SF_vstore(i, j, *px++);
                    }
                    token = strtok_r(NULL, " ", &next_token);
                }
            return(0);
        }

        // argv[0] = "GetVarsFromMat": copy from Julia matrix into existing Stata vars, with no special handling of Julia missings; but Julia NaN mapped to Stata missing
        // argv[1] = matrix name
        if (!strcmp(argv[0], "GetVarsFromMat")) {
            snprintf(buf, BUFLEN, "size(%s,1)", argv[1]);
            size_t nobs = (size_t)jl_unbox_int64(safe_jl_eval_string(buf));
            snprintf(buf, BUFLEN, "size(%s,2)", argv[1]);
            size_t ncols = (size_t)jl_unbox_int64(safe_jl_eval_string(buf));
            if (SF_nvars() < ncols)
                ncols = SF_nvars();
            snprintf(buf, BUFLEN, "let x=%s; eltype(x)==Float64 ? x : Array{Float64, ndims(x)}(x) end", argv[1]);  // assure source matrix is double
            jl_value_t* X = safe_jl_eval_string(buf);
            double* _px = (double*)jl_array_data(X);
            double* px = _px;
            for (ST_int i = 1; i <= ncols; i++) {
                _px += nobs;
                for (ST_int j = SF_in1(); j <= SF_in2() && px < _px; j++)
                    if (SF_ifobs(j))
                        SF_vstore(i, j, *px++);
            }
            return(0);
        }

        // argv[0] = "GetMatFromMat": copy from Julia Matrix{<:Real} into existing Stata matrix; Julia NaN mapped to Stata missing
        // argv[1] = Stata matrix name
        // argv[2] = Julia matrix name
        if (!strcmp(argv[0], "GetMatFromMat")) {
            snprintf(buf, BUFLEN, "size(%s,1)", argv[2]);
            size_t nrows = (size_t)jl_unbox_int64(safe_jl_eval_string(buf));
            snprintf(buf, BUFLEN, "size(%s,2)", argv[2]);
            size_t ncols = (size_t)jl_unbox_int64(safe_jl_eval_string(buf));
            snprintf(buf, BUFLEN, "let x=%s; eltype(x)==Float64 ? x : Array{Float64, ndims(x)}(x) end", argv[2]);  // assure source matrix is double
            jl_value_t* X = safe_jl_eval_string(buf);
            double* px = (double*)jl_array_data(X);
            for (ST_int i = 1; i <= ncols; i++)
                for (ST_int j = 1; j <= nrows; j++)
                    SF_mat_store(argv[1], j, i, *px++);
            return(0);
        }

        // argv[0] = "PutMatToMat": put Stata matrix in a new Julia Matrix{Float64}, converting Stata missings to NaN (not Julia missing)
        // argv[1] = Stata matrix name
        // argv[2] = Julia destination matrix; any existing matrix of that name will be overwritten
        if (!strcmp(argv[0], "PutMatToMat")) {
            char* matname = argv[1];
            ST_int nrows = SF_row(matname);
            ST_int ncols = SF_col(matname);
            snprintf(buf, BUFLEN, "%s = Matrix{Float64}(undef, %i, %i)", argv[2], nrows, ncols);

            jl_value_t* X = safe_jl_eval_string(buf);
            double* px = (double*)jl_array_data(X);

            double NaN = jl_unbox_float64(safe_jl_eval_string("NaN"));
            for (ST_int i = 1; i <= ncols; i++) {
                for (ST_int j = 1; j <= nrows; j++)
                    SF_mat_el(matname, j, i, px);
                if (SF_is_missing((ST_double)*px))
                    *px = NaN;
                px++;
            }
            return(0);
        }
    }
    catch (const char* msg) {
        SF_error((char*)msg);
        SF_error((char*)"\n");
        return(1);
    }
    return(0);
}
