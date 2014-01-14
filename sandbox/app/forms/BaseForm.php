<?php

use Illuminate\Support\MessageBag;

class BaseForm
{

	public function __construct() {
		$errors = new MessageBag();

		if ($old = Input::old("errors")) {
			$errors = $old;
		}

		$this->errors = $errors;
	}

	public function isValid($rules)
	{
		$validator = Validator::make(Input::all(), $rules);
		$this->passes = $validator->passes();
		$this->errors = $validator->errors();
		return $this->passes;
	}

	public function getErrors()
	{
		return $this->errors;
	}

	public function setErrors(MessageBag $errors)
	{
		$this->errors = $errors;
		return $this;
	}

	public function hasErrors()
	{
		return $this->errors->any();
	}

	public function getError($key)
	{
		return $this->getErrors()->first($key);
	}

	public function isPosted()
	{
		return Input::server("REQUEST_METHOD") == "POST";
	}
}
