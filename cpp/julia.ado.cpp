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
#define STDLL_void	extern "C" _declspec(dllexport) void
#else
#define STDLL_int extern "C" ST_int
#define STDLL_bool extern "C" ST_boolean
#define STDLL_void extern "C" void
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
    int8_t (*jl_unbox_bool)(jl_value_t*);
    float (*jl_unbox_float32)(jl_value_t*);
    double (*jl_unbox_float64)(jl_value_t*);
    int64_t(*jl_unbox_int64)(jl_value_t*);
    void* (*jl_unbox_voidpointer)(jl_value_t*);
    jl_value_t* (*jl_exception_occurred)(void);
    jl_value_t* (*jl_call2)(jl_function_t*, jl_value_t*, jl_value_t*);
    jl_value_t* (*jl_call3)(jl_function_t*, jl_value_t*, jl_value_t*, jl_value_t*);
    const char* (*jl_string_ptr)(jl_value_t*);
    int (*jl_gc_enable)(int);
    jl_value_t* (*jl_box_int64)(int64_t);
    jl_value_t* (*jl_pchar_to_string)(const char*, size_t);
    void (*jl_parse_opts)(int*, char***);
} julia_fptrs;

#define JL_eval_string        julia_fptrs.jl_eval_string
#define JL_init               julia_fptrs.jl_init
#define JL_atexit_hook        julia_fptrs.jl_atexit_hook
#define JL_unbox_bool         julia_fptrs.jl_unbox_bool
#define JL_unbox_int64        julia_fptrs.jl_unbox_int64
#define JL_unbox_float32      julia_fptrs.jl_unbox_float32
#define JL_unbox_float64      julia_fptrs.jl_unbox_float64
#define JL_unbox_voidpointer  julia_fptrs.jl_unbox_voidpointer
#define JL_string_ptr         julia_fptrs.jl_string_ptr
#define JL_exception_occurred julia_fptrs.jl_exception_occurred
#define JL_call2              julia_fptrs.jl_call2
#define JL_call3              julia_fptrs.jl_call3
#define JL_gc_enable          julia_fptrs.jl_gc_enable
#define JL_box_int64          julia_fptrs.jl_box_int64
#define JL_pchar_to_string    julia_fptrs.jl_pchar_to_string
#define JL_parse_opts         julia_fptrs.jl_parse_opts
#define JL_get_field          julia_fptrs.jl_get_field

size_t (*JL_nrows)(jl_value_t*), (*JL_ncols)(jl_value_t*);  // will point to Julia functions x->size(x,1), x->size(x,2)
jl_value_t* (*JL_unsafe_makedouble)(jl_value_t*);  // will point to Julia function x->convert(Matrix{Float64}, x)

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
    JL_unbox_bool = (int8_t (*)(jl_value_t*))GetProcAddress(hDLL, "jl_unbox_bool");
    JL_unbox_float32 = (float (*)(jl_value_t*))GetProcAddress(hDLL, "jl_unbox_float32");
    JL_unbox_float64 = (double (*)(jl_value_t*))GetProcAddress(hDLL, "jl_unbox_float64");
    JL_unbox_int64 = (int64_t(*)(jl_value_t*))GetProcAddress(hDLL, "jl_unbox_int64");
    JL_unbox_voidpointer = (void * (*)(jl_value_t*))GetProcAddress(hDLL, "jl_unbox_voidpointer");
    JL_string_ptr = (const char * (*)(jl_value_t*))GetProcAddress(hDLL, "jl_string_ptr");
    JL_exception_occurred = (jl_value_t * (*) (void))GetProcAddress(hDLL, "jl_exception_occurred");
    JL_call2 = (jl_value_t * (*)(jl_function_t*, jl_value_t*, jl_value_t*))GetProcAddress(hDLL, "jl_call2");
    JL_call3 = (jl_value_t * (*)(jl_function_t*, jl_value_t*, jl_value_t*, jl_value_t*))GetProcAddress(hDLL, "jl_call3");
    JL_gc_enable = (int (*)(int))GetProcAddress(hDLL, "jl_gc_enable");
    JL_box_int64 = (jl_value_t * (*)(int64_t))GetProcAddress(hDLL, "jl_box_int64");
    JL_pchar_to_string = (jl_value_t * (*)(const char*, size_t))GetProcAddress(hDLL, "jl_pchar_to_string");
    JL_parse_opts = (void (*)(int*, char***))GetProcAddress(hDLL, "jl_parse_opts");

    return JL_eval_string == NULL || JL_init == NULL || JL_gc_enable == NULL || JL_atexit_hook == NULL || JL_unbox_float32 == NULL || JL_unbox_float64 == NULL || JL_unbox_int64 == NULL || JL_exception_occurred == NULL || JL_call2 == NULL || JL_call3 == NULL || JL_string_ptr == NULL || JL_box_int64 == NULL || JL_pchar_to_string == NULL;
}


jl_value_t* JL_eval(string cmd) {

    jl_value_t* ret = JL_eval_string(cmd.c_str());
    JL_gc_enable(0);
    if (jl_value_t* ex = JL_exception_occurred()) {
        JL_call2(
            JL_eval_string("Base.showerror"),
            JL_eval_string("_Stata_io"),
            ex
        );
        throw jl_string_data(JL_eval_string("String(take!(_Stata_io))"));
    }
    JL_gc_enable(1);

    if (ret)
        return ret;
    throw "Command line failed:\n" + cmd + "\n";
}

template <typename T>
void copytodf(char* touse, ST_int i, T* px, T missval, char nomissing) {
    double val;
    if (nomissing)
        if (touse) {
            char* _tousej = touse;
            for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                if (*_tousej++) {
                    SF_vdata(i, j, &val);
                    *px++ = (T)val;
                }
        } else
            for (ST_int j = 1; j <= SF_nobs(); j++) {
                SF_vdata(i, j, &val);
                *px++ = (T)val;
            }
    else if (touse) {
        char* _tousej = touse;
        for (ST_int j = SF_in1(); j <= SF_in2(); j++)
            if (*_tousej++) {
                SF_vdata(i, j, &val);
                *px++ = SF_is_missing(val) ? missval : (T)val;
            }
    } else
        for (ST_int j = 1; j <= SF_nobs(); j++) {
            SF_vdata(i, j, &val);
            *px++ = SF_is_missing(val) ? missval : (T)val;
        }

}
template <>
void copytodf<double>(char* touse, ST_int i, double* px, double missval, char nomissing) {
    if (touse) {
        char* _tousej = touse;
        for (ST_int j = SF_in1(); j <= SF_in2(); j++)
            if (*_tousej++)
                SF_vdata(i, j, px++);
    } else
        for (ST_int j = 1; j <= SF_nobs(); j++)
            SF_vdata(i, j, px++);
}

template <typename T>
void copyfromdf(char* touse, ST_int i, T* px, size_t offset, char* pmissings, char nomissing, size_t _SF_in2, T shift=0) {
    char* _tousej = touse;
    px += offset;
    if (shift)
        if (nomissing || !pmissings) {
            for (ST_int j = SF_in1(); j <= _SF_in2; j++)
                if (*_tousej++)
                    SF_vstore(i, j, (double)(shift + *px++));
        }
        else
            for (ST_int j = SF_in1(); j <= _SF_in2; j++) {
                if (*_tousej++) {
                    SF_vstore(i, j, *pmissings++ ? SV_missval : (double)(shift + *px));
                    px++;
                }
            }
    else
        if (nomissing || !pmissings) {
            for (ST_int j = SF_in1(); j <= _SF_in2; j++)
                if (*_tousej++)
                    SF_vstore(i, j, (double)(*px++));
        }
        else
            for (ST_int j = SF_in1(); j <= _SF_in2; j++) {
                if (*_tousej++) {
                    SF_vstore(i, j, *pmissings++ ? SV_missval : (double)*px);
                    px++;
                }
            }
}


int8_t int8max;
int16_t int16max;
int32_t int32max;
int64_t int64max;
float NaN32;
double NaN64;
jl_function_t *setindex, *getindex, *parse;
string session = "";  // accumulator for multiline commands
string command = "";  // accumulator for single commands potentially spread across multiple lines, whcih shouldn't have ;'s spliced in
int8_t session_incomplete=0, command_incomplete=0;


STDLL_void copymatS2J(char* stmatname, char* jlmatname) {
    ST_int nrows = SF_row(stmatname);
    ST_int ncols = SF_col(stmatname);
    jl_value_t* X = JL_eval(string(jlmatname) + "= Matrix{Float64}(undef," + to_string(nrows) + "," + to_string(ncols) + ")");  // no more Julia calls till we're done with X, so GC-safe
    double* px = (double*)jl_array_data_(X);
    for (ST_int i = 1; i <= ncols; i++)
        for (ST_int j = 1; j <= nrows; j++) {
            SF_mat_el(stmatname, j, i, px);
            if (SF_is_missing((ST_double)*px))
                *px = NaN64;
            px++;
        }
}

STDLL_void copymatJ2S(jl_value_t* jlmat, char* stmatname) {
    JL_gc_enable(0);
    size_t nrows = JL_nrows(jlmat);
    size_t ncols = JL_ncols(jlmat);

    double* px = (double*)jl_array_data_(JL_unsafe_makedouble(jlmat));
    JL_gc_enable(1);

    for (ST_int i = 1; i <= ncols; i++)
        for (ST_int j = 1; j <= nrows; j++)
            SF_mat_store(stmatname, j, i, *px++);
}

STDLL_void st_data(ST_int* varindexes, ST_int nvars, ST_int nobs, ST_int in1, ST_int in2, char* touse, char* jlmatname, char nomissing) {
    double* px = (double*)jl_array_data_(JL_eval(string(jlmatname) + "= Matrix{Float64}(undef," + to_string(nobs) + "," + to_string(nvars) + ")"));

    #if SYSTEM==APPLEMAC
    dispatch_apply(nvars, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^ (size_t _i)
    #else
    #pragma omp parallel
    {
    #pragma omp for
        for (ST_int _i = 0; _i < nvars; _i++)
    #endif
        {
            ST_int i = varindexes[_i];
            double* pxj = px + _i * nobs;

            if (touse) {
                char* _tousej = touse;
                if (nomissing) {
                    for (ST_int j = in1; j <= in2; j++)
                        if (*_tousej++)
                            SF_vdata(i, j, pxj++);
                }
                else
                    for (ST_int j = in1; j <= in2; j++)
                        if (*_tousej++) {
                            SF_vdata(i, j, pxj);
                            if (SF_is_missing((ST_double)*pxj))
                                *pxj = NaN64;
                            pxj++;
                        }
            }
            else if (nomissing)
                for (ST_int j = 1; j <= nobs; j++)
                    SF_vdata(i, j, pxj++);
            else
                for (ST_int j = 1; j <= nobs; j++) {
                    SF_vdata(i, j, pxj);
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
}


// Stata entry point
STDLL stata_call(int argc, char* argv[])
{
    if (!argc) return 0;

    try {
        char nomissing;

        // argv[0] = "reset": restart parsing context
        if (!strcmp(argv[0], "reset")) {
            session_incomplete = command_incomplete = 0;
            return 0;
        }

        // argv[0] = "start": initiate Julia instance
        // argv[1] = full path to libjulia
        // argv[2] = directory part of argv[1]; should always be supplied but is used in Windows only
        // argv[3] = optional: --threads= argument value (number as a string or "auto")
        if (!strcmp(argv[0], "start")) {
            if (load_julia(argv[1], argv[2]))
                return 998;

            int ac = 1;
            char** av = (char**)malloc(sizeof(char*) * 2);
            av[0] = 0;
            if (argc > 3) {
                string s = "--threads=" + string(argv[3]);
                av[1] = (char*)s.c_str();
                ac++;
            }
            JL_parse_opts(&ac, &av);

            JL_init();

            JL_eval("using REPL");
            JL_eval("const _Stata_io = IOBuffer()");
            JL_eval("const _Stata_context = IOContext(_Stata_io, :limit=>true)");
            JL_eval("const _Stata_stdout = deepcopy(stdout)");

            JL_nrows = (size_t(*)(jl_value_t*)) JL_unbox_voidpointer(JL_eval_string("@cfunction(x->Csize_t(size(x,1)), Csize_t, (Any,))"));
            JL_ncols = (size_t(*)(jl_value_t*)) JL_unbox_voidpointer(JL_eval_string("@cfunction(x->Csize_t(size(x,2)), Csize_t, (Any,))"));
            JL_unsafe_makedouble = (jl_value_t * (*)(jl_value_t*)) JL_unbox_voidpointer(JL_eval_string("@cfunction(x->convert(Array{Float64},x), Any, (Any,))"));

            int8max = numeric_limits<int8_t>::max();
            int16max = numeric_limits<int16_t>::max();
            int32max = numeric_limits<int32_t>::max();
            int64max = numeric_limits<int64_t>::max();
            NaN32 = JL_unbox_float32(JL_eval("NaN32"));
            NaN64 = JL_unbox_float64(JL_eval("NaN64"));
            setindex = (jl_function_t*)JL_eval("Base.setindex!");
            getindex = (jl_function_t*)JL_eval("Base.getindex");
            parse = (jl_function_t*)JL_eval("Meta.parse");
            return 0;
        }

        // argv[0] = "stop": terminate Julia instance, or anyway prep it for termination
        if (!strcmp(argv[0], "stop")) {
            JL_atexit_hook(0);
            FreeLibrary(hDLL);
            return 0;
        }

        if (hDLL == NULL) {
            SF_error((char*)"Julia is not running inside Stata. If Julia was in fact started already\n");
            SF_error((char*)"then Stata has destroyed the Julia instance. You probably need to restart Stata.\n");
            return 999;
        }

        // argv[0] = "eval" or "evalqui": evaluate a Julia expression and return plaintext response in Stata local "ans"
        // argv[1] = expression
        int8_t noisily = strcmp(argv[0], "evalqui");
        if (!noisily || !strcmp(argv[0], "eval")) {
            if (argc > 1) {
                if (noisily) {
                    JL_gc_enable(0);
                    // if (!strcmp(argv[1], "dirname(Base.active_project())")) {
                    //     return 100*(noisily+1) + !strcmp(argv[1], "dirname(Base.active_project())");
                    //     // SF_error((char *) "Stopping!\n");
                    //     // throw "Stopping!";
                    // }
                    JL_eval("ans=" + string(argv[1]));
                    SF_macro_save((char*)"___jlans", jl_string_data(JL_eval("!isnothing(ans) && show(_Stata_context, MIME\"text/plain\"(), ans); ans = String(take!(_Stata_io))")));
                    JL_gc_enable(1);
                }
                else
                    JL_eval(argv[1]);
            }
            return 0;
        }

        // argv[0] = "evalmultiline" or "evalmultilinequi": evaluate a Julia expression and return plaintext response in Stata local "ans"
        // argv[1] = expression
        noisily = strcmp(argv[0], "evalmultilinequi");
        if (!noisily || !strcmp(argv[0], "evalmultiline")) {
            if (argc > 1) {
                command = command_incomplete? command + " " + string(argv[1]) : string(argv[1]);
                if ((command_incomplete = JL_unbox_bool(JL_eval("ans = Meta.parse(raw\"\"\" " + command + " \"\"\") |> (x->x isa Expr && x.head==:incomplete)"))))
                    SF_macro_save((char*)"___jlcomplete", (char*)"0");
                else {
                    session = session_incomplete? session + "; " + command : command;
                    if ((session_incomplete = JL_unbox_bool(JL_eval("ans = Meta.parse(raw\"\"\" " + session + " \"\"\") |> (x->x isa Expr && x.head==:incomplete)"))))
                        SF_macro_save((char*)"___jlcomplete", (char*)"0");
                    else {
                        SF_macro_save((char*)"___jlcomplete", (char*)"1");
                        if (noisily) {
                            JL_eval("_Stata_restdout = redirect_stdout(); _Stata_task=@async read(_Stata_restdout)");
                            JL_eval("ans = eval(REPL.softscope(Meta.parse(raw\"\"\" " + session + " \"\"\")))");
                            JL_eval("close(_Stata_restdout); print(_Stata_io, String(fetch(_Stata_task))); redirect_stdout(_Stata_stdout)");
                            SF_macro_save((char*)"___jlans", jl_string_data(JL_eval("!isnothing(ans) && show(_Stata_context, MIME\"text/plain\"(), ans); ans = String(take!(_Stata_io))")));
                        }
                        else
                            JL_eval("eval(REPL.softscope(Meta.parse(raw\"\"\" " + session + " \"\"\")))");
                    }
                }
            }
            return 0;
        }

        // argv[0] = "PutVarsToMat": put vars in a new Julia Matrix{Float64}, converting Stata pmissings to NaN (not Julia missing)
        // argv[1] = Julia matrix name; any existing matrix of that name will be overwritten
        // argv[2] = null string for full sample copy (no if/in clause)
        nomissing = !strcmp(argv[0], "PutVarsToMatnomissing");
        if (nomissing || !strcmp(argv[0], "PutVarsToMat")) {
            ST_int nobs, in1, in2;
            char* touse;

            if (*argv[2]) {
                nobs = 0;
                touse = (char*)malloc(SF_in2() - SF_in1() + 1);
                char* tousej = touse;
                for (ST_int j=SF_in1(); j<=SF_in2(); j++)
                    nobs += (*tousej++ = (char)SF_ifobs(j));
                if (nobs == SF_nobs()) {
                    free(touse);
                    touse = NULL;
                }
                in1 = SF_in1(); in2 = SF_in2();
            }
            else {
                nobs = SF_nobs();
                touse = NULL;
                in1 = 1; in2 = nobs;
            }

            ST_int *varindexes = (ST_int*)malloc(sizeof(ST_int) * SF_nvars());
            for (ST_int i = 0; i < SF_nvars(); i++) varindexes[i] = i+1;  // copy all variables listed in plugin call before comma, indexed 1..SF_nvars()
            st_data(varindexes, SF_nvars(), nobs, in1, in2, touse, argv[1], nomissing);

            free(varindexes);
            if (touse) free(touse);
            return 0;
        }

        // argv[0] = "PutVarsToDF","PutVarsToDFnomissing": put vars in a new Julia DataFrame, with no special handling of Stata pmissings
        // argv[1] = DataFrame name; any existing DataFrame of that name will be overwritten
        // argv[2] = Julia DataFrame creation command with %i for nobs; 0-length to indicate double-only mode
        // argv[3] = null string for full sample copy (no if/in clause)
        nomissing = !strcmp(argv[0], "PutVarsToDFnomissing");
        if (nomissing || !strcmp(argv[0], "PutVarsToDF")) {
            string dfname = string(argv[1]);

            ST_int nobs;
            char* touse;
            if (*argv[3]) {
                nobs = 0;
                touse = (char*)malloc(SF_in2() - SF_in1() + 1);
                char* tousej = touse;
                for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                    nobs += (*tousej++ = (char)SF_ifobs(j));
                if (nobs == SF_nobs()) {
                    free(touse);
                    touse = NULL;
                }
            } else {
                nobs = SF_nobs();
                touse = NULL;
            }

            void** pxs = (void**)malloc(sizeof(void*) * SF_nvars());
            int64_t* types = (int64_t*)malloc(sizeof(int64_t) * SF_nvars());
            if (*argv[2]) {
                ST_int maxlen = strlen(argv[2]) + 1;
                char* dfcmd = (char*)malloc(maxlen + 20);
                snprintf(dfcmd, maxlen + 20, argv[2], nobs);
                JL_eval(dfcmd);  // construct and allocate DataFrame
                free(dfcmd);

                JL_gc_enable(0);
                for (ST_int i = 0; i < SF_nvars(); i++) {  // get pointers to & types of destination columns w/o multithreading because something in this not thread safe
                    string colname = dfname + "[!," + to_string(i + 1) + "]";
                    string eltype = "eltype(" + colname + ")";
                    types[i] = JL_unbox_int64(JL_eval("stataplugininterface.type2intDict[" + eltype + "]"));
                    pxs[i] = (void*)JL_eval(colname);
                    if (types[i] != 7)
                        pxs[i] = (void*)jl_array_data_((jl_value_t*)pxs[i]);
                }
                JL_gc_enable(1);
            } else {  // double-only mode
                double* _px = (double*)jl_array_data_(JL_eval("stataplugininterface.x = Matrix{Float64}(undef, " + to_string(nobs) + "," + to_string(SF_nvars()) + ");" + dfname + "= DataFrame(stataplugininterface.x, :auto, copycols = false); stataplugininterface.x"));
                for (ST_int i = 0; i < SF_nvars(); i++) {
                    pxs[i] = _px;
                    _px += nobs;
                    types[i] = 6;
                }
            }

            if (nobs) {
#if SYSTEM==APPLEMAC
                dispatch_apply(SF_nvars(), dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^ (size_t i)
#else
#pragma omp parallel
                {
#pragma omp for
                    for (ST_int i = 0; i < SF_nvars(); i++)
#endif
{
                        if (types[i] == 1)
                            copytodf(touse, i + 1, (int8_t*)(pxs[i]), int8max, nomissing);
                        else if (types[i] == 2)
                            copytodf(touse, i + 1, (int16_t*)(pxs[i]), int16max, nomissing);
                        else if (types[i] == 3)
                            copytodf(touse, i + 1, (int32_t*)(pxs[i]), int32max, nomissing);
                        else if (types[i] == 4)
                            copytodf(touse, i + 1, (int64_t*)(pxs[i]), int64max, nomissing);
                        else if (types[i] == 5)
                            copytodf(touse, i + 1, (float*)(pxs[i]), NaN32, nomissing);
                        else if (types[i] == 6)
                            copytodf(touse, i + 1, (double*)(pxs[i]), NaN64, nomissing);
}
#if SYSTEM==APPLEMAC
                    );
#else
                }
#endif

            jl_value_t *helper = JL_eval("stataplugininterface.pushstring!");  // for string copying only

            for (ST_int i = 0; i < SF_nvars(); i++)  // string var copying not thread-safe
		 	    if (types[i]==7) {
                    ST_int ip1 = i + 1;
                    ST_int len;
                    jl_value_t* k = JL_eval("stataplugininterface.k=[0]");  // root k in case of GC during JL_call3; make a vector to use setindex! on it. Just for string copying.

                    if (SF_var_is_strl(ip1))
                        if (touse) {
                            char* _tousej = touse;
                            for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                                if (*_tousej++) {
                                    len = SF_sdatalen(ip1, j);
                                    char* val = (char*)malloc((len + 1) * sizeof(char));
                                    SF_strldata(ip1, j, val, len + 1);
                                    JL_call3(helper, (jl_value_t*)pxs[i], JL_pchar_to_string(val, len), k);  // val -> pxs[i][++k]
                                    free(val);
                                }
                        } else
                           for (ST_int j = 1; j <= nobs; j++) {
                                len = SF_sdatalen(ip1, j);
                                char* val = (char*)malloc((len + 1) * sizeof(char));
                                SF_strldata(ip1, j, val, len + 1);
                                JL_call3(helper, (jl_value_t*)pxs[i], JL_pchar_to_string(val, len), k);  // val -> pxs[i][++k]
                                free(val);
                           }
                    else {  // regular string
                        char val[2046];
                        if (touse) {
                            char* _tousej = touse;
                            for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                                if (*_tousej++) {
                                    SF_sdata(ip1, j, val);
                                    JL_call3(helper, (jl_value_t*)pxs[i], JL_pchar_to_string(val, strlen(val)), k);  // val -> pxs[i][++k]
                                }
                        } else
                            for (ST_int j = 1; j <= nobs; j++) {
                                SF_sdata(ip1, j, val);
                                JL_call3(helper, (jl_value_t*)pxs[i], JL_pchar_to_string(val, strlen(val)), k);  // val -> pxs[i][++k]
                            }
                    }
                }

            free(types);
            free(pxs);
            if (!*argv[2])
                JL_eval("stataplugininterface.x = nothing");
        }
        if (touse) free(touse);
        return 0;
    }
        // argv[0] = "GetVarsFromDF","GetVarsFromDFnomissing": copy from Julia DataFrame into existing Stata vars, with no special handling of Julia pmissings; but Julia NaN mapped to Stata missing
        // argv[1] = DataFrame name
        // argv[2] = name of Stata macro (beginning with "_" if a local) with names of DataFrame cols
        // argv[3] = string rendering of length of that macro
        // argv[4] = string rendering of number of entries in macro
        nomissing = !strcmp(argv[0], "GetVarsFromDFnomissing");
        if (nomissing || !strcmp(argv[0], "GetVarsFromDF")) {
            string dfname = string(argv[1]);
            JL_gc_enable(0);
            size_t df_rows = JL_nrows(JL_eval(dfname));
            JL_gc_enable(1);

            if (!df_rows) return 0;

            char* touse = (char*)malloc(SF_in2() - SF_in1() + 1);
            char* tousej = touse;
            size_t ST_rows = 0;
            ST_int _SF_in2 = SF_in1();  // will end up equalling last row of Stata data set to use: will be SF_in2(), or less if source df is short
            for (; _SF_in2 <= SF_in2() && ST_rows < df_rows; _SF_in2++)
                ST_rows += (*tousej++ = (char)SF_ifobs(_SF_in2));
            if (--_SF_in2 == SF_in2() && ST_rows < df_rows) {
                free(touse);
                throw "Too few rows to receive data.";
            }
            size_t ncols = atoi(argv[4]);

            char* next_colname;
            ST_int maxlen = atoi(argv[3]) + 1;
            char* colnames = (char*)malloc(maxlen);
            (void)SF_macro_use(argv[2], colnames, maxlen);
            char* colname = strtok_r(colnames, " ", &next_colname);
            void** pxs = (void**)malloc(ncols * sizeof(void*));
            const char** types = (const char**)malloc(sizeof(const char *) * ncols);
            char** pmissings = (char**)malloc(sizeof(void*) * SF_nvars());
            size_t* offsets = (size_t*)malloc(sizeof(size_t) * SF_nvars());

            JL_gc_enable(0);
            for (ST_int i = 0; i < ncols; i++) {
                string colref = dfname + "." + string(colname);
                JL_eval("stataplugininterface.x =" + colref + "|> (x-> x |> eltype |> nonmissingtype <: CategoricalValue ? levelcode.(x) : x)");
                pxs[i] = (void*)JL_eval("stataplugininterface.x");
                types[i] = JL_string_ptr(JL_eval(" stataplugininterface.x |> eltype |> nonmissingtype |> Symbol |> String"));

                int64_t allowsmissing = JL_unbox_int64(JL_eval("eltype(stataplugininterface.x) isa Union"));

                if (allowsmissing) {
                    pmissings[i] = (char*)jl_array_data_(JL_eval("map(ismissing,stataplugininterface.x)"));
                    offsets[i] = (size_t)((jl_array_t*)pxs[i])->ref.ptr_or_offset;  // needed for GenericMemory-based arrays in Julia >1.10. Ugly to access this way.
                }
                else {
                    pmissings[i] = NULL;
                    offsets[i] = 0;
                }
                if (strcmp(types[i], "String"))
                    pxs[i] = allowsmissing? ((jl_array_t*)pxs[i])->ref.mem->ptr : (void*)jl_array_data_((jl_value_t*)pxs[i]);  // in Julia >= 1.11, jl_array_data_() returns an offset when eltype is a union https://hackmd.io/@vtjnash/GenericMemory

                colname = strtok_r(NULL, " ", &next_colname);
            }
            JL_gc_enable(1);

#if SYSTEM==APPLEMAC
            dispatch_apply(ncols, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^ (size_t i)
#else
//#pragma omp parallel
            {
//#pragma omp for
                for (ST_int i = 0; i < ncols; i++)
#endif
                {
                    if      (!strcmp(types[i], "Int8"))
                        copyfromdf(touse, i + 1, (int8_t*)pxs[i], offsets[i], pmissings[i], nomissing, _SF_in2, (int8_t) 0);
                    else if (!strcmp(types[i], "Int16"))
                        copyfromdf(touse, i + 1, (int16_t*)pxs[i], offsets[i], pmissings[i], nomissing, _SF_in2, (int16_t)0);
                    else if (!strcmp(types[i], "Int32"))
                        copyfromdf(touse, i + 1, (int32_t*)pxs[i], offsets[i], pmissings[i], nomissing, _SF_in2, (int32_t)0);
                    else if (!strcmp(types[i], "Int64"))
                        copyfromdf(touse, i + 1, (int64_t*)pxs[i], offsets[i], pmissings[i], nomissing, _SF_in2, (int64_t)0);
                    else if (!strcmp(types[i], "Float32"))
                        copyfromdf(touse, i + 1, (float*)pxs[i], offsets[i], pmissings[i], nomissing, _SF_in2, (float)0);
                    else if (!strcmp(types[i], "Float64"))
                        copyfromdf(touse, i + 1, (double*)pxs[i], offsets[i], pmissings[i], nomissing, _SF_in2, (double)0);
                    else if (!strcmp(types[i], "Date"))
                        copyfromdf(touse, i + 1, (int64_t*)pxs[i], offsets[i], pmissings[i], nomissing, _SF_in2, (int64_t) -715510);  // shift by days from 1/1/0001 to 1/1/1960
                    else if (!strcmp(types[i], "DateTime"))
                        copyfromdf(touse, i + 1, (int64_t*)pxs[i], offsets[i], pmissings[i], nomissing, _SF_in2, (int64_t) -61820064000000);  // shift by milliseconds from 1/1/0001 to 1/1/1960
                }
#if SYSTEM==APPLEMAC
                );
#else
            }
#endif
            for (ST_int i = 0; i < ncols; i++)  // copying string vars apparently not thread-safe because of jl_*() calls
                if (!strcmp(types[i], "String")) {
                    char* _tousej = touse;
                    ST_int ip1 = i + 1;
                    int64_t k = 1;
                    char* val;
                    for (ST_int j = SF_in1(); j <= SF_in2(); j++)
                        if (*_tousej++) {
                            val = (char*)JL_string_ptr(JL_call2(getindex, (jl_value_t*)pxs[i], JL_box_int64(k++)));
                            SF_sstore(ip1, j, val);
                        }
                }

            free(touse);
            free(colnames);
            free(pxs);
            free(pmissings);
            return 0;
        }

        // argv[0] = "GetVarsFromMat": copy from Julia matrix into existing Stata vars, with no special handling of Julia missings; but Julia NaN mapped to Stata missing
        // argv[1] = matrix name
        // argv[2] = null string for full sample copy (no if/in clause)

        if (!strcmp(argv[0], "GetVarsFromMat")) {
            jl_value_t* mat = JL_eval("ans = " + string(argv[1]));
            size_t nobs = JL_nrows(mat);
            size_t ncols = JL_ncols(mat);
            if (SF_nvars() < ncols) ncols = SF_nvars();
            double* px = (double*)jl_array_data_(JL_unsafe_makedouble(mat));  // no more Julia calls till we're done with X, so GC-safe

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
                    if (*argv[2]) {
                        for (ST_int j = SF_in1(); j <= SF_in2() && pxj < _pxj; j++)
                            if (SF_ifobs(j))
                                SF_vstore(ip1, j, *pxj++);
                    } else
                        for (ST_int j = 1; pxj < _pxj; j++)
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
            copymatJ2S(JL_eval("ans = " + string(argv[2])), argv[1]);
            return 0;
        }

        // argv[0] = "PutMatToMat": put Stata matrix in a new Julia Matrix{Float64}, converting Stata missings to NaN (not Julia missing)
        // argv[1] = Stata matrix name
        // argv[2] = Julia destination matrix; any existing matrix of that name will be overwritten
        if (!strcmp(argv[0], "PutMatToMat")) {
            copymatS2J(argv[1], argv[2]);
            return 0;
        }
    }
    catch (const char* msg) {
        JL_gc_enable(1);
        SF_macro_save((char*)"___jlans", (char*) msg);
        return 999;
    }
    return 0;
}
