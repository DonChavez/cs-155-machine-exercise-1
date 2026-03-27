%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

void yyerror(const char *msg);
int yylex(void);

typedef struct Node {
    char        label[64];
    struct Node *children[3];
    int          num_children;
} Node;

Node *make_node(const char *label) {
    Node *n = malloc(sizeof(Node));
    strncpy(n->label, label, 63);
    n->label[63] = '\0';
    n->num_children = 0;
    return n;
}

Node *make_node1(const char *label, Node *c1) {
    Node *n = make_node(label);
    n->children[0] = c1;
    n->num_children = 1;
    return n;
}

Node *make_node2(const char *label, Node *c1, Node *c2) {
    Node *n = make_node(label);
    n->children[0] = c1;
    n->children[1] = c2;
    n->num_children = 2;
    return n;
}

Node *make_node3(const char *label, Node *c1, Node *c2, Node *c3) {
    Node *n = make_node(label);
    n->children[0] = c1;
    n->children[1] = c2;
    n->children[2] = c3;
    n->num_children = 3;
    return n;
}

int depth = 0;

void indent(int d) {
    for (int i = 0; i < d * 2; i++) printf(" ");
}

void print_tree(Node *n) {
    if (!n) return;
    indent(depth);
    printf("%s\n", n->label);
    depth++;
    for (int i = 0; i < n->num_children; i++)
        print_tree(n->children[i]);
    depth--;
}

void free_tree(Node *n) {
    if (!n) return;
    for (int i = 0; i < n->num_children; i++)
        free_tree(n->children[i]);
    free(n);
}
%}

%union {
    int   ival;
    float fval;
    void *node;
}

%token <ival> NUM
%token <fval> FNUM
%token PLUS MINUS TIMES DIVIDE LPAREN RPAREN
%token NEWLINE
%token POW

%left PLUS MINUS
%left TIMES DIVIDE
%right POW
%right UMINUS

%type <node> expr term factor

%%

program:
      /* empty */
    | program line
    ;

line:
      NEWLINE               { /* blank line, skip */ }
    | expr NEWLINE
        {
            depth = 0;
            print_tree((Node *)$1);
            free_tree((Node *)$1);
            printf("\n");
        }
    ;

expr:
      expr PLUS term
        { $$ = make_node3("expr", (Node *)$1, make_node("+"), (Node *)$3); }
    | expr MINUS term
        { $$ = make_node3("expr", (Node *)$1, make_node("-"), (Node *)$3); }
    | term
        { $$ = make_node1("expr", (Node *)$1); }
    ;

term:
      term TIMES factor
        { $$ = make_node3("term", (Node *)$1, make_node("*"), (Node *)$3); }
    | term DIVIDE factor
        { $$ = make_node3("term", (Node *)$1, make_node("/"), (Node *)$3); }
    | factor
        { $$ = make_node1("term", (Node *)$1); }
    ;

factor:
      NUM
        {
            char buf[32];
            snprintf(buf, sizeof(buf), "%d", $1);
            $$ = make_node1("factor", make_node(buf));
        }
    | FNUM
        {
            char buf[32];
            snprintf(buf, sizeof(buf), "%g", $1);
            $$ = make_node1("factor", make_node(buf));
        }
    | LPAREN expr RPAREN    { $$ = $2; }
    | MINUS factor %prec UMINUS
        { $$ = make_node2("factor", make_node("-"), (Node *)$2); }
    | factor POW factor
        { $$ = make_node3("factor", (Node *)$1, make_node("^"), (Node *)$3); }
    ;

%%

void yyerror(const char *msg) {
    fprintf(stderr, "Parse error: %s\n", msg);
}

int main(void) {
    return yyparse();
}
