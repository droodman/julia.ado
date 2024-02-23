#define NOMINMAX

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <limits>
#include "stplugin.h"
#include <julia.h>
using namespace std;

#if SYSTEM==APPLEMAC
#include <dispatch/dispatch.h>
#else
#include <omp.h>
#endif

#define SF_varindex(s,a) ((_stata_)->stfindvar((s),(a)))

#if SYSTEM==STWIN32
#define STDLL_int	extern "C" _declspec(dllexport) ST_int
#define STDLL_bool	extern "C" _declspec(dllexport) ST_boolean
#else
#define STDLL_int extern "C" ST_int
#define STDLL_bool extern "C" ST_boolean
#endif

// wrappers for Stata interface entry points within this shared library, for Julia to find
STDLL jlSF_vdata(ST_int i, ST_int j, ST_double* z) { return SF_vdata(i, j, z); }
STDLL jlSF_vstore(ST_int i, ST_int j, ST_double val) { return SF_vstore(i, j, val); }
STDLL jlSF_sdata(ST_int i, ST_int j, char* s) { return SF_sdata(i, j, s); }
STDLL jlSF_sstore(ST_int i, ST_int j, char* s) { return SF_sstore(i, j, s); }
STDLL_int jlSF_sdatalen(ST_int i, ST_int j) { return SF_sdatalen(i, j); }
STDLL jlSF_strldata(ST_int i, ST_int j, char* s, ST_int len) { return SF_strldata(i, j, s, len); }
STDLL_bool jlSF_var_is_string(ST_int i) { return SF_var_is_string(i); }
STDLL_bool jlSF_var_is_strl(ST_int i) { return SF_var_is_strl(i); }
STDLL_bool jlSF_var_is_binary(ST_int i, ST_int j) { return SF_var_is_binary(i, j); }
STDLL_int jlSF_nobs(void) { return SF_nobs(); }
STDLL_int jlSF_nvars(void) { return SF_nvars(); }
STDLL_int jlSF_nvar(void) { return SF_nvar(); }
STDLL_bool jlSF_ifobs(ST_int j) { return SF_ifobs(j); }
STDLL_int jlSF_in1(void) { return SF_in1(); }
STDLL_int jlSF_in2(void) { return SF_in2(); }
STDLL jlSF_mat_el(char* mat, ST_int i, ST_int j, ST_double* z) { return SF_mat_el(mat, i, j, z); }
STDLL jlSF_mat_store(char* mat, ST_int i, ST_int j, ST_double val) { return SF_mat_store(mat, i, j, val); }
STDLL_int jlSF_col(char* mat) { return SF_col(mat); }
STDLL_int jlSF_row(char* mat) { return SF_row(mat); }
STDLL jlSF_macro_save(char* mac, char* tosave) { return SF_macro_save(mac, tosave); }
STDLL jlSF_macro_use(char* mac, char* contents, ST_int maxlen) { return SF_macro_use(mac, contents, maxlen); }
STDLL jlSF_scal_save(char* scal, double val) { return SF_scal_save(scal, val); }
STDLL jlSF_scal_use(char* scal, double* z) { return SF_scal_use(scal, z); }
STDLL jlSF_display(char* s) { return SF_display(s); }
STDLL jlSF_error(char* s) { return SF_error(s); }
STDLL_bool jlSF_is_missing(ST_double z) { return SF_is_missing(z); }
STDLL jlSF_missval(void) { return SV_missval; }
STDLL_int jlSF_varindex(char* s, ST_int abbrev) { return SF_varindex(s, abbrev); }


struct {  // https://github.com/JuliaLang/juliaup/issues/758#issuecomment-1832621780
    jl_value_t* (*jl_eval_string)(const char*);
    void (*jl_init)(void);
    void (*jl_atexit_hook)(int);
    float (*jl_unbox_float32)(jl_value_t*);
    double (*jl_unbox_float64)(jl_value_t*);
    int64_t (*jl_unbox_int64)(jl_value_t*);
    jl_value_t* (*jl_exception_occurred)(void);
    jl_value_t* (*jl_call2)(jl_function_t*, jl_value_t*, jl_value_t*);
    const char* (*jl_string_ptr)(jl_value_t*);
} julia_fptrs;

#define JL_eval_string        julia_fptrs.jl_eval_string
#define JL_init               julia_fptrs.jl_init
#define JL_atexit_hook        julia_fptrs.jl_atexit_hook
#define JL_unbox_int64        julia_fptrs.jl_unbox_int64
#define JL_unbox_float32      julia_fptrs.jl_unbox_float32
#define JL_unbox_float64      julia_fptrs.jl_unbox_float64
#define JL_string_ptr         julia_fptrs.jl_string_ptr
#define JL_exception_occurred julia_fptrs.jl_exception_occurred
#define JL_call2              julia_fptrs.jl_call2

#if SYSTEM==STWIN32
#include "windows.h"
#define strtok_r strtok_s
#define snprintf sprintf_s
#else
#include <dlfcn.h>
#define HINSTANCE void *
#define GetProcAddress dlsym
#define FreeLibrary dlclose
#endif

HINSTANCE hDLL;

int load_julia(const char* fulllibpath, const char* libdir) {

#if SYSTEM==STWIN32
    SetDllDirectoryA(libdir);
    hDLL = LoadLibraryExA(fulllibpath, NULL, LOAD_WITH_ALTERED_SEARCH_PATH);
#else
    hDLL = dlopen(fulllibpath, RTLD_LAZY);
#endif

    if (hDLL == NULL) return 999;

    JL_eval_string = (jl_value_t * (*)(const char*))GetProcAddress(hDLL, "jl_eval_string");
    JL_init = (void (*)(void))GetProcAddress(hDLL, "jl_init");
    JL_atexit_hook = (void (*)(int))GetProcAddress(hDLL, "jl_atexit_hook");
    JL_unbox_float32 = (float (*)(jl_value_t*))GetProcAddress(hDLL, "jl_unbox_float32");
    JL_unbox_float64 = (double (*)(jl_value_t*))GetProcAddress(hDLL, "jl_unbox_float64");
    JL_unbox_int64 = (int64_t (*)(jl_value_t*))GetProcAddress(hDLL, "jl_unbox_int64");
    JL_string_ptr = (const char * (*)(jl_value_t*))GetProcAddress(hDLL, "jl_string_ptr");
    JL_exception_occurred = (jl_value_t * (*) (void))GetProcAddress(hDLL, "jl_exception_occurred");
    JL_call2 = (jl_value_t * (*)(jl_function_t*, jl_value_t*, jl_value_t*))GetProcAddress(hDLL, "jl_call2");

    return JL_eval_string == NULL || JL_init == NULL || JL_atexit_hook == NULL || JL_unbox_float32 == NULL || JL_unbox_float64 == NULL || JL_unbox_int64 == NULL || JL_exception_occurred == NULL || JL_call2 == NULL /* || JL_string_ptr == NULL*/;
}


jl_value_t* JL_eval(string cmd) {
    jl_value_t* ret = JL_eval_string(cmd.c_str());
    if (jl_value_t* ex = JL_exception_occurred()) {
        JL_call2(
            JL_eval_string("Base.showerror"),
            JL_eval_string("_Stata_io"),
            ex
        );
        throw jl_string_data(JL_eval_string("String(take!(_Stata_io))"));
    }
    if (ret)
        return ret;
    throw "Command line failed:\n" + cmd + "\n";
}


template <typename T>
void copytodf(char* touse, ST_int i, T* px, T missval, char NoMissing) {
    char* _tousej = touse;
    double val;
    if (NoMissing) {
        for (ST_int j = SF_in1(); j <= SF_in2(); j++)
            if (*_tousej++) {
                SF_vdata(i, j, &val);
                *px++ = (T)val;
            }
    } else
        for (ST_int j = SF_in1(); j <= SF_in2(); j++)
            if (*_tousej++) {
                SF_vdata(i, j, &val);
                *px++ = SF_is_missing(val) ? missval : (T)val;
            }
}

int8_t int8max;
int16_t int16max;
int32_t int32max;
int64_t int64max;
float NaN32;
double NaN64;

// Stata entry point
STDLL stata_call(int argc, char* argv[])
{
    if (!argc) return 0;

    try {
        char NoMissing;

        // argv[0] = "start": initiate Julia instance
        // argv[1] = full path to libjulia
        // argv[2] = directory part of argv[1], Windows only
        if (!strcmp(argv[0], "start")) {
            if (load_julia(argv[1], argv[2]))
                return 998;

            JL_init();
            JL_eval("const _Stata_io = IOBuffer(); const _Stata_context=IOContext(_Stata_io, :limit=>true)");
            
            int8max = numeric_limits<int8_t>::max();
            int16max = numeric_limits<int16_t>::max();
            int32max = numeric_limits<int32_t>::max();
            int64max = numeric_limits<int64_t>::max();
            NaN32 = JL_unbox_float32(JL_eval("NaN32"));
            NaN64 = JL_unbox_float64(JL_eval("NaN64"));

            return 0;
        }

        // argv[0] = "stop": terminate Julia instance, or anyway prep it for termination
        if (!strcmp(argv[0], "stop")) {
            JL_atexit_hook(0);
            FreeLibrary(hDLL);
            return 0;
        }

        // argv[0] = "eval": evaluate a Julia expression and return plaintext response in Stata local "ans"; slow if the return value is, e.g., a large array
        // argv[1] = expression
        if (!strcmp(argv[0], "eval")) {
            if (argc > 1)
                SF_macro_save((char*)"_ans", jl_string_data(JL_eval("show(_Stata_context, MIME\"text/plain\"(), begin (" + string(argv[1]) + ") end); String(take!(_Stata_io))")));
            return 0;
        }

        // argv[0] = "eval": evaluate a Julia expression but for speed return no response
        // argv[1] = expression
        if (!strcmp(argv[0], "evalqui")) {
            if (argc > 1)
                JL_eval("begin (" + string(argv[1]) +"); 0 end");
            return 0;
        }

        // argv[0] = "PutVarsToMat": put vars in a new Julia Matrix{Float64}, converting Stata missings to NaN (not Julia missing)
        // argv[1] = Julia matrix name; any existing matrix of that name will be overwritten
        NoMissing = !strcmp(argv[0], "PutVarsToMatNoMissing");
        if (NoMissing || !strcmp(argv[0], "PutVarsToMat")) {
            ST_int nobs = 0;
            char* touse = (char*)malloc(SF_in2() - SF_in1() + 1);
            char* tousej = touse;
            for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                nobs += (*tousej++ = (char)SF_ifobs(j));

            jl_value_t* X = JL_eval(string(argv[1]) + "= Matrix{Float64}(undef," + to_string(nobs) + "," + to_string(SF_nvars()) + ")");
            double* px = (double*)jl_array_data(X);

#if SYSTEM==APPLEMAC
            dispatch_apply(SF_nvars(), dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^ (size_t i)
#else
#pragma omp parallel
            {
#pragma omp for
                for (ST_int i = 0; i < SF_nvars(); i++)
#endif
                {
                    char* _tousej = touse;
                    ST_int ip1 = i + 1;
                    double* pxj = px + i * nobs;

                    if (NoMissing) {
                        for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                            if (*_tousej++)
                                SF_vdata(ip1, j, pxj++);
                    }
                    else
                        for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                            if (*_tousej++) {
                                SF_vdata(ip1, j, pxj);
                                if (SF_is_missing((ST_double)*pxj))
                                    *pxj = NaN64;
                                pxj++;
                            }
                }
#if SYSTEM==APPLEMAC
                );
#else
            }
#endif
            free(touse);
            return 0;
        }

        // argv[0] = "PutVarsToDF": put vars in a new, all-Float64 Julia DataFrame, with no special handling of Stata missings
        // argv[1] = DataFrame name; any existing DataFrame of that name will be overwritten
        // argv[2] = name of Stata macro (beginning with "_" if a local) with DataFrame creation command template with %i for nobs
        // argv[3] = string rendering of length of that macro
        NoMissing = !strcmp(argv[0], "PutVarsToDFNoMissing");
        if (NoMissing || !strcmp(argv[0], "PutVarsToDF")) {
            string dfname = string(argv[1]);

            ST_int nobs = 0;
            char* touse = (char*)malloc(SF_in2() - SF_in1() + 1);
            char* tousej = touse;
            for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                nobs += (*tousej++ = (char)SF_ifobs(j));

            ST_int maxlen = atoi(argv[3]) + 1;
            char* dfcmd = (char*)malloc(maxlen);
            SF_macro_use(argv[2], dfcmd, maxlen);
            char* dfcmd2 = (char*)malloc(maxlen + 20);
            snprintf(dfcmd2, maxlen + 20, dfcmd, nobs);
            JL_eval(dfcmd2);  // construct and allocate DataFrame
            free(dfcmd);
            free(dfcmd2);

            void** pxs = (void**)malloc(sizeof(void*) * SF_nvars());
            int64_t* types = (int64_t*)malloc(sizeof(int64_t) * SF_nvars());
            for (ST_int i = 0; i < SF_nvars(); i++) {  // get pointers to & types of destination columns w/o multithreading because jl_*() routines not thread safe
                pxs[i] = (void*)jl_array_data(JL_eval(dfname + "[!," + to_string(i + 1) + "]"));
                types[i] = JL_unbox_int64(JL_eval("stataplugininterface.type2intDict[eltype(" + dfname + "[!," + to_string(i + 1) + "])]"));
            }

#if SYSTEM==APPLEMAC
            dispatch_apply(SF_nvars(), dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^ (size_t i)
#else
#pragma omp parallel
            {
#pragma omp for
                for (ST_int i = 0; i < SF_nvars(); i++)
#endif

                    if (types[i] == 1)
                        copytodf(touse, i + 1, (int8_t*)(pxs[i]), int8max, NoMissing);
                    else if (types[i] == 2)
                        copytodf(touse, i + 1, (int16_t*)(pxs[i]), int16max, NoMissing);
                    else if (types[i] == 3)
                        copytodf(touse, i + 1, (int32_t*)(pxs[i]), int32max, NoMissing);
                    else if (types[i] == 4)
                        copytodf(touse, i + 1, (int64_t*)(pxs[i]), int64max, NoMissing);
                    else if (types[i] == 5)
                        copytodf(touse, i + 1, (float*)(pxs[i]), NaN32, NoMissing);
                    else if (types[i] == 6) {
                        char* _tousej = touse;
                        double* px = (double*)(pxs[i]);
                        for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                            if (*_tousej++)
                                SF_vdata(i, j, px++);
                    } else
                        0;  // XXX handle strings
#if SYSTEM==APPLEMAC
                );
#else
            }
#endif
            if (!NoMissing) {
                JL_eval("allowmissing!(" + dfname + ")");
                JL_eval("map(x -> (x, x |> eltype |> nonmissingtype) |> (xt -> ((x,t)=xt; t<:Number && replace!(x, (t<:Integer ? typemax(t) : t(NaN)) => missing); 0)), eachcol(df))");
            }

            free(types);
            free(touse);
            free(pxs);
            return 0;
        }
            // argv[0] = "GetVarsFromDF","GetVarsFromDFNoMissing": copy from Julia DataFrame into existing Stata vars, with no special handling of Julia missings; but Julia NaN mapped to Stata missing
            // argv[1] = DataFrame name
            // argv[2] = name of Stata macro (beginning with "_" if a local) with names of DataFrame cols
            // argv[3] = string rendering of length of that macro
            // argv[4] = string rendering of number of entries in macro
            NoMissing = !strcmp(argv[0], "GetVarsFromDFNoMissing");
            if (NoMissing || !strcmp(argv[0], "GetVarsFromDF")) {
                size_t nobs = (size_t)JL_unbox_int64(JL_eval("size(" + string(argv[1]) + ",1)"));

                char* touse = (char*)malloc(SF_in2() - SF_in1() + 1);
                char* tousej = touse;
                size_t ST_rows = 0;
                for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                    ST_rows += (*tousej++ = (char)SF_ifobs(j));
                if (nobs > ST_rows) {
                    free(touse);
                    throw "Too few rows to receive data.";
                }

                size_t ncols = atoi(argv[4]);

                char* next_colname;
                ST_int maxlen = atoi(argv[3]) + 1;
                char* colnames = (char*)malloc(maxlen);
                (void)SF_macro_use(argv[2], colnames, maxlen);
                char* colname = strtok_r(colnames, " ", &next_colname);

                double** maxpx = (double**)malloc(ncols * sizeof(double*));
                
                #define BUFLEN 4096
                char buf[BUFLEN];
                for (ST_int i = 0; i < ncols; i++) {
                    snprintf(buf, BUFLEN, "stataplugininterface.x=parent((%s)[!,:%s]); eltype(stataplugininterface.x)!=Float64 && (stataplugininterface.x = Array{Float64}(stataplugininterface.x)); stataplugininterface.x", argv[1], colname);  // assure source vector is double
                    maxpx[i] = (double*)jl_array_data(JL_eval(buf));
                    snprintf(buf, BUFLEN, "parentindices((%s)[!,:%s]) |> (x -> isone(length(x)) ? 1 : x[2])", argv[1], colname);
                    maxpx[i] += nobs * (int64_t) JL_unbox_int64(JL_eval(buf));
                    colname = strtok_r(NULL, " ", &next_colname);
                }

#if SYSTEM==APPLEMAC
                dispatch_apply(ncols, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^ (size_t i)
#else
#pragma omp parallel
                {
#pragma omp for
                    for (ST_int i = 0; i < ncols; i++)
#endif
                    {
                        double* pxj = maxpx[i] - nobs;
                        char* _tousej = touse;
                        ST_int ip1 = i + 1;
                        if (NoMissing) {
                            for (ST_int j = SF_in1(); j <= SF_in2() && pxj < maxpx[i]; j++)
                                if (*_tousej++)
                                    SF_vstore(ip1, j, *pxj++);
                        }
                        else
                            for (ST_int j = SF_in1(); j <= SF_in2() && pxj < maxpx[i]; j++) {
                                if (*_tousej++) {
                                    SF_vstore(ip1, j, *pxj != *pxj ? SV_missval : *pxj);  // *pxj != *pxj detects NaN
                                    pxj++;
                                }
                            }
                    }
#if SYSTEM==APPLEMAC
                    );
#else
                }
#endif
                free(touse);
                free(colnames);
                free(maxpx);
                return 0;
            }

            // argv[0] = "GetVarsFromMat": copy from Julia matrix into existing Stata vars, with no special handling of Julia missings; but Julia NaN mapped to Stata missing
            // argv[1] = matrix name
            if (!strcmp(argv[0], "GetVarsFromMat")) {
                size_t nobs  = (size_t)JL_unbox_int64(JL_eval("size(" + string(argv[1]) + ",1)"));
                size_t ncols = (size_t)JL_unbox_int64(JL_eval("size(" + string(argv[1]) + ",2)"));

                if (SF_nvars() < ncols)
                    ncols = SF_nvars();

                jl_value_t* X = JL_eval("let x=" + string(argv[1]) + "; eltype(x) == Float64 ? x : Array{Float64}(x) end");
                double* px = (double*)jl_array_data(X);

#if SYSTEM==APPLEMAC
                dispatch_apply(ncols, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^ (size_t i)
#else
#pragma omp parallel
                {
#pragma omp for
                    for (ST_int i = 0; i < ncols; i++)
#endif
                    {
                        double* pxj = px + i * nobs;
                        double* _pxj = pxj + nobs;
                        ST_int ip1 = i + 1;
                        for (ST_int j = SF_in1(); j <= SF_in2() && pxj < _pxj; j++)
                            if (SF_ifobs(j))
                                SF_vstore(ip1, j, *pxj++);
                    }
#if SYSTEM==APPLEMAC
                    );
#else
                }
#endif
                return 0;
            }

            // argv[0] = "GetMatFromMat": copy from Julia Matrix{<:Real} into existing Stata matrix; Julia NaN mapped to Stata missing
            // argv[1] = Stata matrix name
            // argv[2] = Julia matrix name
            if (!strcmp(argv[0], "GetMatFromMat")) {
                size_t nrows = (size_t)JL_unbox_int64(JL_eval("size(" + string(argv[2]) + ",1)"));
                size_t ncols = (size_t)JL_unbox_int64(JL_eval("size(" + string(argv[2]) + ",2)"));

                double* px = (double*)jl_array_data(JL_eval("let x=" + string(argv[2]) + "; eltype(x) == Float64 ? x : Array{Float64}(x)end"));
                for (ST_int i = 1; i <= ncols; i++)
                    for (ST_int j = 1; j <= nrows; j++)
                        SF_mat_store(argv[1], j, i, *px++);
                return 0;
            }

            // argv[0] = "PutMatToMat": put Stata matrix in a new Julia Matrix{Float64}, converting Stata missings to NaN (not Julia missing)
            // argv[1] = Stata matrix name
            // argv[2] = Julia destination matrix; any existing matrix of that name will be overwritten
            if (!strcmp(argv[0], "PutMatToMat")) {
                char* matname = argv[1];
                ST_int nrows = SF_row(matname);
                ST_int ncols = SF_col(matname);
                jl_value_t* X = JL_eval(string(argv[2]) + "= Matrix{Float64}(undef," + to_string(nrows) + "," + to_string(ncols) + ")");
                double* px = (double*)jl_array_data(X);

                double NaN = JL_unbox_float64(JL_eval("NaN"));
                for (ST_int i = 1; i <= ncols; i++)
                    for (ST_int j = 1; j <= nrows; j++) {
                        SF_mat_el(matname, j, i, px);
                        if (SF_is_missing((ST_double)*px))
                            *px = NaN;
                        px++;
                    }
                return 0;
            }
        }
    catch (const char* msg) {
        SF_error((char*)msg);
        SF_error((char*)"\n");
        return 999;
    }
    return 0;
}
