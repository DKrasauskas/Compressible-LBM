#include "../Graphics/opengl/Shader.h"

// Create vertex/ fragment shaders from GLSL files
Shader::Shader(const char* inputVertex, const char* inputFragment, Log& log) {
    log.new_state("Shader");
    unsigned int vertex, fragment;
    success = true;
    log.log_state("Parsing:" + std::string(inputVertex));
    log.log_state("Parsing:" + std::string(inputFragment));
    char* source = Shader::Parse(inputVertex, log);
    char* source2 = Shader::Parse(inputFragment, log);
    std::string type1 = "vertex shader";
    std::string type2 = "fragment shader";
    BuildShaders(vertex, source, GL_VERTEX_SHADER, type1, log);
    BuildShaders(fragment, source2, GL_FRAGMENT_SHADER, type2, log);
    ID = glCreateProgram();
    glAttachShader(ID, vertex);
    glAttachShader(ID, fragment);
    Link(ID, log);
    free(source);
    free(source2);
}
Shader::Shader(const char* inputCompute, Log& log) {
    log.new_state("Shader");
    unsigned int compute;
    std::string type = "compute";
    success = true;
    log.log_state("Parsing:" + std::string(inputCompute));
    char* source = Shader::Parse(inputCompute, log);
    BuildShaders(compute, source, GL_COMPUTE_SHADER, type, log);
    ID = glCreateProgram();
    glAttachShader(ID, compute);
    Link(ID, log);
    free(source);
}

Shader::~Shader() {
    glDeleteProgram(ID);
}
char* Shader::Parse(string input, Log& log) {
    ifstream in(input);
    try{
        !in.is_open() ? throw std::runtime_error("ERR: GLSL FILE NOT FOUND") : NULL;
    }
    catch (const std::runtime_error& e){
        log.log_state("Runtime Error: "  + std::string(e.what()));
        log.log_file.close();
        //rethrow
        throw std::runtime_error("ERR: GLSL FILE NOT FOUND");
    }
    std::stringstream buffer;
    buffer << in.rdbuf();
    string s = buffer.str();
    unsigned int alloc_size = sizeof(char) * (s.length() + 1);
    char* out = (char*)malloc(alloc_size);
    log.log_mem(alloc_size);
    for (int i = 0; i < s.length(); i++) {
        out[i] = s[i];
    }
    out[s.length()] = '\0';
    return out;
}
void Shader::BuildShaders(unsigned int& shader, const char* source, uint32_t shader_type, std::string& type, Log& log) {
    shader = glCreateShader(shader_type);
    glShaderSource(shader, 1, &source, NULL);
    int compile_status_local;
    char err[512];
    glCompileShader(shader);
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compile_status_local);
    try{
        if (!compile_status_local) {
            glGetShaderInfoLog(shader, 512, NULL, err);
            log.log_state("Compilation failed: " + type);
            log.log_state(err);
            throw std::runtime_error("ERR: GLSL FILE NOT FOUND");
        }
    }
    catch (const std::runtime_error& e){
        this->success = false;
        log.log_state("Runtime Error"  + std::string(e.what()));
        log.log_file.close();
        //rethrow
        throw std::runtime_error("ERR: GLSL FILE NOT FOUND");
    }
}

void Shader::Link(unsigned int& program, Log& log) {
    glLinkProgram(program);
    int compile_status_local;
    char err[512];
    glGetProgramiv(program, GL_LINK_STATUS, &compile_status_local);
    try{
        if (!compile_status_local) {
            glGetProgramInfoLog(program, 512, NULL, err);
            log.log_state("Linking failed");
            log.log_state(err);
            throw std::runtime_error("ERR: GLSL FILE NOT FOUND");
        }
    }
    catch(const std::runtime_error& e){
        this->success = false;
        log.log_state("Runtime Error : " + std::string(e.what()));
        log.log_file.close();
        //rethrow
        throw std::runtime_error("ERR: GLSL FILE NOT FOUND");
    }
}


