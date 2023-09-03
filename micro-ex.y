%{

#include <unordered_map>
#include <iostream>
#include <utility>
#include <vector>
#include <string>


#include <cstdlib>
#include <cstdio>


extern "C" {
    extern int yylex(void);
}

void yyerror(const std::string &err_msg);

class Symbol {
	public :
		std::string name;
		int type;
		
		Symbol() : name(), type() {}
		Symbol(const std::string &name_, int type_) : name(name_), type(type_) {}
		Symbol(const Symbol &symbol_) : name(symbol_.name), type(symbol_.type) {}
		Symbol(Symbol &&symbol_) { swap(symbol_); }
		~Symbol() {}
		
		Symbol& operator=(const Symbol &symbol_) {
			name = symbol_.name;
			type = symbol_.type;
			return *this;
		}
		Symbol& operator=(Symbol &&symbol_) {
			swap(symbol_);
			return *this;
		}
		
		void swap(Symbol &symbol_) {
			name.swap(symbol_.name);
			int tmp = type; type = symbol_.type; symbol_.type = tmp;
		}
};

typedef std::unordered_map<std::string, int> Table;
typedef Table::iterator Table_Iter;

unsigned int lineCount = 1;
unsigned int lbCounter = 0;
unsigned int tmpCounter = 0;

extern const int V_TYPE  = 0;
extern const int A_TYPE  = 1;
extern const int I_TYPE  = 2;
extern const int IA_TYPE = 3;
extern const int F_TYPE  = 4;
extern const int FA_TYPE = 5;
extern const int B_TYPE  = 8;
extern const int T_TYPE  = 16;

const int OP_ADD = 1;
const int OP_SUB = 2;
const int OP_MUL = 3;
const int OP_DIV = 4;

const int OP_E   = 5;
const int OP_NE  = 6;
const int OP_L   = 7;
const int OP_LE  = 8;
const int OP_G   = 9;
const int OP_GE  = 10;

const int FOR_TO     = 0;
const int FOR_DOWNTO = 1;

inline std::string& name(void* symbol) { return ((Symbol*)symbol)->name; }
inline int&         type(void* symbol) { return ((Symbol*)symbol)->type; }

inline std::string get_tmp_name(unsigned n) { return "T&" + std::to_string(n); }
inline std::string new_tmp_name() { return get_tmp_name(++tmpCounter); }
inline std::string new_tmp(int tmp_type);

inline std::string get_lb_name(unsigned n) { return "lb&" + std::to_string(n); }
inline int new_lb() { return ++lbCounter; }

std::vector<std::string> ASM;
Table symbol_table;
std::vector<int> tmp_type_table;
std::vector<int> label_stack;
std::vector<Symbol> decl_var_table;
std::vector<std::string> params_table;
int current_label_no = 0, current_label_no_2 = 0;

inline void check_symbol(const std::string &symbol_name);
inline int get_symbol_type(const std::string &symbol_name);

void* new_symbol(const std::string &symbol_name, int symbol_type) { return new Symbol(symbol_name, symbol_type); }
void add_symbol(void *symbol);
void release_symbol(void *symbol) { delete ((Symbol*)symbol); }

void* arith_op(void *lhs, int op, void *rhs);
void    cmp_op(void *lhs, int op, void *rhs);
void  j_cmp_op(int lb_no, int op);

void decl_tmps();

inline void asm_write_cmd(const std::string &cmd);
inline void asm_add_lb(int no);

%}


%union {
	void* symbol;
	int vali;
}

%token <symbol> INTEGER FLOAT ID INTEGER_LITERAL FLOAT_LITERAL

%token <symbol> PROGRAM BEGIN_ END IF THEN ELSE ENDIF
				FOR TO DOWNTO STEP ENDFOR WHILE ENDWHILE
				DECLARE AS ASSIGN AND OR FUNCTION RETURN
				NOT_EQUAL EQUAL GREATER LESS GREATERE_QUAL LESSE_QUAL

%left '-' '+'
%left '*' '/'
%nonassoc PLUS UMINUS

%type <symbol> program_prefix expr var decl_var type for_assign param
%type <vali> while_prefix for_dir for_rb

%%


start : program_prefix program {
									asm_write_cmd("HALT " + name($1));
									decl_tmps();
									release_symbol($1);
							   }

program_prefix : PROGRAM ID {
								add_symbol($2);
								asm_write_cmd("START " + name($2));
								$$ = $2;
							}
			   ;

program: BEGIN_ stmt_list END ;


stmt_list : stmt
		  |	stmt_list stmt
		  ;

stmt : expr_stmt
	 | decl_stmt
	 | assign_stmt
	 | if_stmt
	 | while_stmt
	 | for_stmt
	 | func_stmt
	 | ';'
	 ;


expr_stmt : expr ';' { release_symbol($1); }
		  ;

expr : expr '+' expr { $$ = arith_op($1, OP_ADD, $3); }
	 | expr '-' expr { $$ = arith_op($1, OP_SUB, $3); }
	 | expr '*' expr { $$ = arith_op($1, OP_MUL, $3); }
	 | expr '/' expr { $$ = arith_op($1, OP_DIV, $3); }
	 | '+' expr %prec PLUS {
								if (type($2) & A_TYPE) {
									yyerror("array type '" + name($2) + "' does not have unary minus");
								}
								$$ = $2;
						   }
	 | '-' expr %prec UMINUS {
								if (type($2) & A_TYPE) {
									yyerror("array type '" + name($2) + "' does not have unary minus");
								}
								if (type($2) == I_TYPE) {
									const std::string tmp_name(new_tmp(I_TYPE));
									asm_write_cmd("I_UMINUS " + name($2) + "," + tmp_name);
									name($2) = tmp_name;
									$$ = $2;
								}
								else {
									const std::string tmp_name(new_tmp(F_TYPE));
									asm_write_cmd("F_UMINUS " + name($2) + "," + tmp_name);
									name($2) = tmp_name;
									$$ = $2;
								}
							 }
	 | '(' expr ')' { $$ = $2; }
	 | var { $$ = $1; }
	 | INTEGER_LITERAL { $$ = $1; }
	 | FLOAT_LITERAL { $$ = $1; }
	 ;

var : ID {
			type($1) = get_symbol_type(name($1));
			$$ = $1;
		 }
	| ID '[' expr ']' {
							type($1) = get_symbol_type(name($1));
							if (!(type($1) & A_TYPE)) {
								yyerror("'" + name($1) + "' is not array");
							}
							if (type($3) != I_TYPE) {
								yyerror("index of array '" + name($3) + "' is not Integer type");
							}
							name($1) = name($1) + "[" + name($3) + "]";
							type($1) ^= A_TYPE;
							release_symbol($3);
							$$ = $1;
					  }


decl_stmt : DECLARE decl_var_list AS type ';' {
												for (size_t i = 0; i < decl_var_table.size(); ++i) {
													Symbol &new_var = decl_var_table[i];
													new_var.type |= type($4);
													int var_type = new_var.type;
													std::string var_name = new_var.name;
													if (var_type & A_TYPE) {
														size_t lb = var_name.find('[');
														size_t rb = var_name.find(']', lb);
														new_var.name = var_name.substr(0, lb);
														add_symbol(&new_var);
														asm_write_cmd("Declare " + new_var.name + ", " + name($4) + "_array, " + var_name.substr(lb+1, rb-lb-1));
													}
													else {
														add_symbol(&new_var);
														asm_write_cmd("Declare " + var_name + ", " + name($4));
													}
												}
												decl_var_table.clear();
												release_symbol($4);
											  }
		  ;

decl_var_list : decl_var_list ',' decl_var {
												decl_var_table.push_back(*(Symbol*)$3);
												release_symbol($3);
										   }
		 | decl_var {
						decl_var_table.push_back(*(Symbol*)$1);
						release_symbol($1);
					}
		 ;

decl_var : ID { $$ = $1; }
		 | ID '[' expr ']' {
								if (type($3) != I_TYPE) {
									yyerror("size of array '" + name($3) + "' is not Integer type");
								}
								name($1) = name($1) + "[" + name($3) + "]";
								type($1) |= A_TYPE;
								release_symbol($3);
								$$ = $1;
						   }
		 ;
	
type : INTEGER { $$ = new_symbol("Integer", I_TYPE); }
	 | FLOAT { $$ = new_symbol("Float", F_TYPE); }
	 ;


assign_stmt : var ASSIGN expr ';' {
										if (type($1) & A_TYPE) {
											yyerror("array type '" + name($1) + "' can not be assigned");
										}
										if (type($3) & A_TYPE) {
											yyerror("array type '" + name($3) + "' can not assign to");
										}
										if (type($1) != type($3)) {
											yyerror("can not assign '" + name($3) + "' to '" + name($1) + "' which have difference type");
										}
										if (type($1) == I_TYPE) {
											asm_write_cmd("I_Store " + name($3) + "," + name($1));
										}
										else {
											asm_write_cmd("F_Store " + name($3) + "," + name($1));
										}
										release_symbol($1);
										release_symbol($3);
								  }
			;


if_stmt : IF '(' cmp_expr ')' THEN stmt_list if_suffix {
															asm_add_lb(label_stack.back());
															label_stack.pop_back();
													   }
		;

cmp_expr : expr NOT_EQUAL expr	   { cmp_op($1, OP_NE, $3); }
		 | expr EQUAL expr		   { cmp_op($1, OP_E,  $3); }
		 | expr GREATER expr       { cmp_op($1, OP_G,  $3); }
		 | expr LESS expr		   { cmp_op($1, OP_L,  $3); }
		 | expr GREATERE_QUAL expr { cmp_op($1, OP_GE, $3); }
		 | expr LESSE_QUAL expr	   { cmp_op($1, OP_LE, $3); }
		 ;

if_suffix : ENDIF
		  | else_prefix stmt_list ENDIF
		  ;

else_prefix : ELSE {
						const int lb_no = new_lb();
						const std::string lb_name(get_lb_name(lb_no));
						asm_write_cmd("J " + lb_name);
						asm_add_lb(label_stack.back());
						label_stack.pop_back();
						label_stack.push_back(lb_no);
				   }
			;


while_stmt : while_prefix '(' cmp_expr ')'  stmt_list ENDWHILE {
																	asm_write_cmd("J " + get_lb_name($1));
																	asm_add_lb(label_stack.back());
																	label_stack.pop_back();
															   }
		   ;

while_prefix : WHILE {
						if (!current_label_no) {
							asm_add_lb(new_lb());
						}
						$$ = current_label_no;
					 }


for_stmt : FOR '(' for_assign for_dir expr for_rb stmt_list ENDFOR {
																		if (type($5) != I_TYPE) {
																			yyerror("type of '" + name($3) + "' is not Integer for ending in for-loop");
																		}
																		if ($4 == FOR_TO) {
																			asm_write_cmd("INC " + name($3));
																			asm_write_cmd("I_CMP " + name($3) + "," + name($5));
																			j_cmp_op($6, OP_GE);
																		}
																		else {
																			asm_write_cmd("DEC " + name($3));
																			asm_write_cmd("I_CMP " + name($3) + "," + name($5));
																			j_cmp_op($6, OP_LE);
																		}
																   }
		 | FOR '(' for_assign for_dir expr STEP expr for_rb stmt_list ENDFOR {
																				if (type($5) != I_TYPE) {
																					yyerror("type of '" + name($3) + "' is not Integer for ending in for-loop");
																				}
																				if (type($7) != I_TYPE) {
																					yyerror("type of '" + name($3) + "' is not Integer for stepping in for-loop");
																				}
																				if ($4 == FOR_TO) {
																					asm_write_cmd("I_ADD " + name($3) + "," + name($7) + "," + name($3));
																					asm_write_cmd("I_CMP " + name($3) + "," + name($5));
																					j_cmp_op($8, OP_GE);
																				}
																				else {
																					asm_write_cmd("I_SUB " + name($3) + "," + name($7) + "," + name($3));
																					asm_write_cmd("I_CMP " + name($3) + "," + name($5));
																					j_cmp_op($8, OP_LE);
																				}
																			 }
		 ;

for_assign : var ASSIGN expr {
								if (type($1) != I_TYPE) {
									yyerror("type of '" + name($1) + "' is not Integer for iterating in for-loop ");
								}
								if (type($3) != I_TYPE) {
									yyerror("type of '" + name($3) + "' is not Integer for assigning to in for-loop");
								}
								asm_write_cmd("I_Store " + name($3) + "," + name($1));
								release_symbol($3);
								$$ = $1;
							 }
				;

for_dir : TO { $$ = FOR_TO; }
		| DOWNTO { $$ = FOR_DOWNTO; }
		;

for_rb : ')' {
				const int lb_no = new_lb();
				asm_add_lb(lb_no);
				$$ = lb_no;
			 }
	  ;


func_stmt : ID '(' param_list ')' ';' {
											std::string cmd = "CALL " + name($1);
											for (size_t i = 0; i < params_table.size(); ++i) {
												cmd += "," + params_table[i];
											}
											asm_write_cmd(cmd);
											params_table.clear();
											release_symbol($1);
									  }
		  ;

param_list : param_list ',' param {
										params_table.push_back(name($3));
										release_symbol($3);
								  }
		   | param {
						params_table.push_back(name($1));
						release_symbol($1);
				   }
		   ;

param : expr { $$ = $1; }
	  ;


%%

void yyerror(const std::string &err_msg) {
	std::cerr << "[Error] line " << lineCount << " : " << err_msg << "\n";
	exit(1);
}


void asm_write_cmd(const std::string &cmd) {
	ASM.push_back(cmd);
	current_label_no = current_label_no_2, current_label_no_2 = 0;
}

void asm_add_lb(int no) {
	ASM.push_back(get_lb_name(no) + ":");
	current_label_no = current_label_no_2 = no;
}


std::string new_tmp(int tmp_type) {
	Symbol tmp_symbol(new_tmp_name(), tmp_type);
	tmp_type_table.push_back(tmp_type);
	return tmp_symbol.name;
}


void add_symbol(void *symbol) {
	if (symbol_table.find(name(symbol)) != symbol_table.end()) {
		yyerror("redeclaration of '" + name(symbol) + "'");
	}
	symbol_table[name(symbol)] = type(symbol);
}

void check_symbol(const std::string &symbol_name) {
	if (symbol_table.find(symbol_name) == symbol_table.end()) {
		yyerror("'" + symbol_name + "' was not declared");
	}
}

int get_symbol_type(const std::string &symbol_name) {
	check_symbol(symbol_name);
	return symbol_table[symbol_name];
}


void decl_tmps() {
	for (size_t i = 0; i < tmp_type_table.size(); ++i) {
		if (tmp_type_table[i] == I_TYPE) {
			asm_write_cmd("Declare " + get_tmp_name(i+1) + ", Integer");
		}
		else {
			asm_write_cmd("Declare " + get_tmp_name(i+1) + ", Float");
		}
	}
}


void* arith_op(void *lhs, int op, void *rhs) {
	int lhs_type = type(lhs), rhs_type = type(rhs);
	if (lhs_type != I_TYPE && lhs_type != F_TYPE) {
		yyerror("the type of '" + name(lhs) + "' can not to calculate");
	}
	if (rhs_type != I_TYPE && rhs_type != F_TYPE) {
		yyerror("the type of '" + name(rhs) + "' can not to calculate");
	}
	if (lhs_type != rhs_type) {
		yyerror("can not calculate '" + name(lhs) + "' and '" + name(rhs) + "' which have difference type");
	}
	
	std::string op_name;
	switch(op) {
		case OP_ADD :
			op_name = "ADD";
			break;
		case OP_SUB :
			op_name = "SUB";
			break;
		case OP_MUL :
			op_name = "MUL";
			break;
		case OP_DIV :
			op_name = "DIV";
			break;
	}
	if (lhs_type == I_TYPE) {
		const std::string tmp_name(new_tmp(I_TYPE));
		asm_write_cmd("I_" + op_name + " " + name(lhs) + "," + name(rhs) + "," + tmp_name);
		name(lhs) = tmp_name;
	}
	else {
		const std::string tmp_name(new_tmp(F_TYPE));
		asm_write_cmd("F_" + op_name + " " + name(lhs) + "," + name(rhs) + "," + tmp_name);
		name(lhs) = tmp_name;
	}
	release_symbol(rhs);
	return lhs;
}

void cmp_op(void *lhs, int op, void *rhs) {
	int lhs_type = type(lhs), rhs_type = type(rhs);
	if (lhs_type != I_TYPE && lhs_type != F_TYPE) {
		yyerror("the type of '" + name(lhs) + "' can not to compare");
	}
	if (rhs_type != I_TYPE && rhs_type != F_TYPE) {
		yyerror("the type of '" + name(rhs) + "' can not to compare");
	}
	if (lhs_type != rhs_type) {
		yyerror("can not compare '" + name(lhs) + "' and '" + name(rhs) + "' which have difference type");
	}
	
	if (lhs_type == I_TYPE) {
		asm_write_cmd("I_CMP " + name(lhs) + "," + name(rhs));
	}
	else {
		asm_write_cmd("F_CMP " + name(lhs) + "," + name(rhs));
	}
	
	const int lb_no = new_lb();
	j_cmp_op(lb_no, op);
	label_stack.push_back(lb_no);
	release_symbol(lhs);
	release_symbol(rhs);
}

void j_cmp_op(int lb_no, int op) {
	std::string op_name;
	switch(op) {
		case OP_NE :
			op_name = "E";
			break;
		case OP_E :
			op_name = "NE";
			break;
		case OP_L :
			op_name = "GE";
			break;
		case OP_G :
			op_name = "LE";
			break;
		case OP_LE :
			op_name = "G";
			break;
		case OP_GE :
			op_name = "L";
			break;
	}
	asm_write_cmd("J" + op_name + " " + get_lb_name(lb_no));
}