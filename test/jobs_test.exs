defmodule ShadowHash.JobsTest do
  use ExUnit.Case

  alias ShadowHash.Job.DictionaryStreamJob
  alias ShadowHash.Job.DictionaryJob
  alias ShadowHash.Job.JobParser
  alias ShadowHash.Job.BruteforceJob

  test "Dictionary job division" do
    jobs = [%DictionaryStreamJob{stream: ["a", "b", "c", "d", "e", "f"]}]

    {current, jobs} = JobParser.take_job(jobs, 2)
    assert current == %DictionaryJob{names: ["a", "b"]}

    {current, jobs} = JobParser.take_job(jobs, 2)
    assert current == %DictionaryJob{names: ["c", "d"]}

    {current, jobs} = JobParser.take_job(jobs, 2)
    assert current == %DictionaryJob{names: ["e", "f"]}

    assert :empty == JobParser.take_job(jobs, 2)
  end

  test "Bruteforce division with limit" do
    jobs = [%BruteforceJob{begin: 100, last: 104, charset: [1,2,3]}]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 100 && l == 101 && charset == [1,2,3]

    {%BruteforceJob{begin: b, last: l}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 102 && l == 103 && charset == [1,2,3]

    {%BruteforceJob{begin: b, last: l}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 104 && l == 104 && charset == [1,2,3]

    assert :empty == JobParser.take_job(jobs, 2)
  end

  test "Bruteforce division with infinity" do
    jobs = [%BruteforceJob{begin: 100, last: :inf, charset: [1,2,3]}]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 100 && l == 101 && charset == [1,2,3]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 102 && l == 103 && charset == [1,2,3]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 104 && l == 105 && charset == [1,2,3]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 106 && l == 107 && charset == [1,2,3]

    assert :empty != JobParser.take_job(jobs, 2)
  end

  test "Dictionary coalesce with bruteforce" do
    jobs = [%DictionaryStreamJob{stream: ["a", "b", "c", "d", "e", "f"]}, %BruteforceJob{begin: 100, last: :inf, charset: [1,2,3,4]}]

    # Test dictionary
    {current, jobs} = JobParser.take_job(jobs, 2)
    assert current == %DictionaryJob{names: ["a", "b"]}

    {current, jobs} = JobParser.take_job(jobs, 2)
    assert current == %DictionaryJob{names: ["c", "d"]}

    {current, jobs} = JobParser.take_job(jobs, 2)
    assert current == %DictionaryJob{names: ["e", "f"]}

    # Should transition to a bruteforce...

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 100 && l == 101 && charset == [1,2,3,4]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 102 && l == 103 && charset == [1,2,3,4]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 104 && l == 105 && charset == [1,2,3,4]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 106 && l == 107 && charset == [1,2,3,4]

    assert :empty != JobParser.take_job(jobs, 2)
  end

  test "Empty Dictionary coalesce with bruteforce" do
    jobs = [%DictionaryStreamJob{stream: []}, %BruteforceJob{begin: 100, last: :inf, charset: [1,2,3,4]}]

    # Should transition to a bruteforce...

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 100 && l == 101 && charset == [1,2,3,4]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 102 && l == 103 && charset == [1,2,3,4]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 104 && l == 105 && charset == [1,2,3,4]

    {%BruteforceJob{begin: b, last: l, charset: charset}, jobs} = JobParser.take_job(jobs, 2)
    assert b == 106 && l == 107 && charset == [1,2,3,4]

    assert :empty != JobParser.take_job(jobs, 2)
  end
end
