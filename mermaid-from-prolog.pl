:- dynamic class/3.
:- dynamic className/1.
:- dynamic properties/1.
:- dynamic methods/1.
:- dynamic property/3.
:- dynamic method/4.
:- dynamic relation/5.


init :- 
    assert(class(className('User'), properties([property('id', 'uuid', '-'), property('name', 'string', '-')]), methods([]))),
    assert(class(className('Contact'), properties([property('id', 'uuid', -), property('name', 'string', '-'), property('telefone', 'string', '-'), property('user_id', 'uuid', '-')]), methods([]))),
    assert(relation('User', '1', '*-->', '1..*', 'Contact')).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Insert the specification of a class, a list of attributes, a list of operations and a set of relations between classes;
insert_class :- 
    write('Class name: '), read(ClassName),
    write('Number of properties: '), read(NumProps),
    read_properties(NumProps, Properties),
    write('Number of methods: '), read(NumMethods),
    read_methods(NumMethods, Methods),
    assert(class(className(ClassName), properties(Properties), methods(Methods))).

read_properties(0, []) :- !.
read_properties(N, [property(Name, Type, Privacy) | Rest]) :-
    N > 0,
    write('Property name: '), read(Name),
    write('Property type: '), read(Type),
    write('Is property private (yes/no): '), read(PrivacyInput),
    (PrivacyInput == yes -> Privacy = '-' ; Privacy = '+'),
    N1 is N - 1,
    read_properties(N1, Rest).

read_methods(0, []) :- !.
read_methods(N, [method(Name, Params, ReturnType, Privacy) | Rest]) :-
    N > 0,
    write('Method name: '), read(Name),
    write('Number of parameters: '), read(NumParams),
    read_parameters(NumParams, Params),
    write('Return type: '), read(ReturnType),
    write('Is method private (yes/no): '), read(PrivacyInput),
    (PrivacyInput == yes -> Privacy = '-' ; Privacy = '+'),
    N1 is N - 1,
    read_methods(N1, Rest).

read_parameters(0, []) :- !.
read_parameters(N, [Param | Rest]) :-
    N > 0,
    write('Parameter: '), read(Param),
    N1 is N - 1,
    read_parameters(N1, Rest).

add_property_to_class(ClassName, PropertyName, PropertyType, Privacy) :-
    assert(property(PropertyName, PropertyType, Privacy)),
    retract(class(className(ClassName), properties(Properties), Methods)),
    assert(class(className(ClassName), properties([property(PropertyName, PropertyType, Privacy) | Properties]), Methods)).

add_method_to_class(ClassName, MethodName, Parameters, ReturnType, Privacy) :-
    assert(method(MethodName, Parameters, ReturnType, Privacy)),
    retract(class(className(ClassName), Properties, methods(Methods))),
    assert(class(className(ClassName), Properties, methods([method(MethodName, Parameters, ReturnType, Privacy) | Methods]))).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Create the relations and validate each relation specification verifying if the classes exists and involved are already defined;
add_relation(Class1, Multiplicity1, RelationType, Multiplicity2, Class2) :-
    class_exists(Class1),
    class_exists(Class2),    
    not(relation_exists(Class1, Class2)),    
    assert(relation(Class1, Multiplicity1, RelationType, Multiplicity2, Class2)).

class_exists(ClassName) :-
    class(className(ClassName), _, _).

relation_exists(Class1, Class2) :-    
    relation(Class1, _, _, _, Class2).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Count the number of attributes of a class;
count_properties(ClassName, Count) :-
    class(className(ClassName), properties(Properties), _),
    length(Properties, Count).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Generate mermaid code in order to visualize the graph representing the class diagram.
generate_mermaid(Code) :-
    findall(ClassCode, generate_class_code(ClassCode), ClassCodes),
    findall(RelationCode, generate_relation_code(RelationCode), RelationCodes),
    flatten([["classDiagram"], ClassCodes, RelationCodes], CodeList),
    atomic_list_concat(CodeList, '\n', Code).

generate_class_code(ClassCode) :-
    class(className(ClassName), properties(Properties), methods(Methods)),
    format(atom(ClassHeader), 'class ~w {', [ClassName]),
    maplist(generate_property_code, Properties, PropertyCodes),
    maplist(generate_method_code, Methods, MethodCodes),
    append([ClassHeader | PropertyCodes], MethodCodes, ClassLines),
    append(ClassLines, ["}"], CompleteClassLines),
    atomic_list_concat(CompleteClassLines, '\n', ClassCode).

generate_property_code(property(Name, Type, Privacy), Code) :-
    format(atom(Code), '  ~w ~w: ~w', [Privacy, Name, Type]).

generate_method_code(method(Name, Params, ReturnType, Privacy), Code) :-
    (Params = [] -> ParamsString = '' ; atomic_list_concat(Params, ', ', ParamsString)),
    format(atom(Code), '  ~w ~w(~w): ~w', [Privacy, Name, ParamsString, ReturnType]).

generate_relation_code(RelationCode) :-
    relation(Class1, Multiplicity1, RelationType, Multiplicity2, Class2),
    format(atom(RelationCode), '~w "~w" ~w "~w" ~w', [Class1, Multiplicity1, RelationType, Multiplicity2, Class2]).

print_mermaid_code :-
    generate_mermaid(Code),
    write(Code), nl.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%