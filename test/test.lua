package.cpath = package.cpath .. ";../bin/Debug/?.dll"

lfb = require("lfb")
inspect = require("inspect")

assert(lfb.load_bfbs_file("../third_party/flatbuffers/tests/monster_test.bfbs"))

function test_no_type()
	buf, err = lfb.encode("Abcd", {})
	assert(err == "no type Abcd")
end

function test_required()
	buf = assert(lfb.encode("Monster", {}))
	t, err = lfb.decode("Monster", buf)
	assert(err == "illegal required field Monster.name")

	buf = assert(lfb.encode("Monster", {name="abc"}))
	t = assert(lfb.decode("Monster", buf))
	assert(t.name == "abc")
end  -- test_required()

function test_too_short()
	TO_SHORT = "buffer is too short"
	t, err = lfb.decode("Monster", "")
	assert(err == TO_SHORT)
	t, err = lfb.decode("Monster", "123")
	assert(err == TO_SHORT)
	assert(not lfb.decode("Monster", "1234"))
	assert(not lfb.decode("Monster", "1234"))
end

function test_not_table()
	buf, err = lfb.encode("Monster", nil)
	assert(nil == buf)
	assert(err == "lua data is not table but nil")
	buf, err = lfb.encode("Monster", 1234)
	assert(err == "lua data is not table but number")
	buf, err = lfb.encode("Monster", print)
	assert(err == "lua data is not table but function")
end  -- test_not_table()

function test_type_convert()
	buf = assert(lfb.encode("Monster", {name=123}))
	t = assert(lfb.decode("Monster", buf))
	assert("123" == t.name)
	buf = assert(lfb.encode("Test", {a=1, b=256}))  -- Test.b is byte
	t = assert(lfb.decode("Test", buf))
	assert(1 == t.a and 0 == t.b)
end  -- test_type_convert()

function test_string_field()
	assert(lfb.encode("Monster", {name=""}))
	buf, err = lfb.encode("Monster", {name=print})
	assert(err == "string field Monster.name is function")
end  -- test_string_field()

function test_encode_struct()
	buf, err = lfb.encode("Test", {})
	assert(err == "missing struct field Test.a")
	buf, err = lfb.encode("Test", {a=1})
	assert(err == "missing struct field Test.b")
	buf, err = lfb.encode("Test", {a=1, b=2, c=3})
	assert(err == "illegal field Test.c")
	buf = assert(lfb.encode("Test", {a=1, b=2}))
	t = assert(lfb.decode("Test", buf))
	assert(t.a == 1 and t.b == 2)
	buf, err = lfb.encode("Test", {a=1, b={}})
	assert(err == "can not convert field Test.b(table) to integer")
end  -- test_encode_struct()

function test_encode_nested_struct()
	org = {x=1,y=2,z=3.3,test1=0.001,test2=0,test3={a=1,b=2}}
	buf = assert(lfb.encode("Vec3", org))
	t = assert(lfb.decode("Vec3", buf))
	assert(1 == t.test3.a)
	assert(2 == t.test3.b)
	assert(0 == t.test2)
end  -- test_encode_nested_struct()

function test_to_num()
	assert(lfb.test_to_num(0)["int8"] == 0)
	assert(lfb.test_to_num("123")["int8"] == 123)
	assert(lfb.test_to_num(9223372036854775807)["int64"] == 9223372036854775807)
	assert(lfb.test_to_num("9223372036854775807")["int64"] == 9223372036854775807)
	t = lfb.test_to_num(0.1)
	assert(t["double"] == 0.1)
	assert(tostring(t["float"]) == "0.10000000149012")
	assert(t["int8"] == "can not convert field test(0.1) to integer")
	assert(lfb.test_to_num(256)["uint8"] == 0)
	assert(lfb.test_to_num(nil)["uint8"] == "can not convert field test(nil) to integer")
	t = lfb.test_to_num(true)
	assert(t.int8 == 1)
	t = lfb.test_to_num(false)
	assert(t.uint8 == 0)
end  -- test_to_num()

function test_enum()
	local name = "TestSimpleTableWithEnum"
	buf = assert(lfb.encode(name, {}))
	t = assert(lfb.decode(name, buf))
	assert(2 == t.color)
	buf = assert(lfb.encode(name, {color = 123}))
	t = assert(lfb.decode(name, buf))
	assert(123 == t.color)
	buf = assert(lfb.encode(name, {color = "Green"}))
	t = assert(lfb.decode(name, buf))
	assert(2 == t.color)
	buf = assert(lfb.encode(name, {color = "Blue"}))
	t = assert(lfb.decode(name, buf))
	assert(8 == t.color)
end  -- test_enum()

function test_encode_illegal_field()
	buf, err = lfb.encode("Monster", {abcd=1})
	assert(err == "illegal field Monster.abcd")
end  -- test_encode_illegal_field()

function test_mygame_example2_monster()
	buf = assert(lfb.encode("MyGame.Example2.Monster", {}))
	-- no type MyGame.Example2.Monster
end  -- test_mygame_example2_monster()

function test_encode_depricated_field()
	buf, err = lfb.encode("Monster", {friendly=true})
	assert(err == "deprecated field Monster.friendly")
end  -- test_encode_depricated_field()

function test_bool_field()
	buf = assert(lfb.encode("Monster", {name="", testbool=true}))
	t = assert(lfb.decode("Monster", buf))
	assert(true == t.testbool)
	buf = assert(lfb.encode("Monster", {name="", testbool=false}))
	t = assert(lfb.decode("Monster", buf))
	assert(false == t.testbool)
	buf = assert(lfb.encode("Monster", {name="", testbool=123}))
	t = assert(lfb.decode("Monster", buf))
	assert(true == t.testbool)
end  -- test_bool_field()

function test_vector_field()
	buf, err = lfb.encode("Monster", {name="", inventory=1234})
	assert(err == "array field Monster.inventory is not array but number")
	buf, err = lfb.encode("Monster", {name="", inventory={1.1}})
	assert(err == "can not convert field Monster.inventory[1](1.1) to integer")
end  -- test_vector_field()

function test_all()
	test_no_type()
	test_required()
	test_too_short()
	test_not_table()
	test_type_convert()
	test_string_field()
	test_encode_struct()
	test_encode_nested_struct()
	test_to_num()
	test_enum()
	test_encode_illegal_field()
	-- Todo: test_mygame_example2_monster()
	test_encode_depricated_field()
	test_bool_field()
	test_vector_field()
	print("All test passed.")
end  -- test_all()

test_all()
