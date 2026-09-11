/*
 * input.c
 * Copyright (C) 1998 Brainchild Design - http://brainchilddesign.com/
 * 
 * Copyright (C) 2001 Chuck Mason <cemason@users.sourceforge.net>
 *
 * Copyright (C) 2002 Florian Schulze <crow@icculus.org>
 *
 * This file is part of Jump'n'Bump.
 *
 * Jump'n'Bump is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Jump'n'Bump is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "globals.h"

static int num_joys=0;
static SDL_Joystick *joys[4];

#define JOY_DEAD_ZONE ((32767 * 12) / 100)
#define JOY_FACE_BUTTONS 4
#define JOY_START_BUTTON 7

static int joy_available(int num)
{
	return num >= 0 && num < num_joys && num < 4 && joys[num] != NULL;
}

static int joy_hat_pressed(int num, Uint8 direction)
{
	Uint8 hat;

	if (!joy_available(num) || SDL_JoystickNumHats(joys[num]) < 1)
		return 0;

	hat = SDL_JoystickGetHat(joys[num], 0);
	return (hat & direction) != 0;
}

static int joy_left(int num)
{
	int axis_left = 0;

	if (!joy_available(num))
		return 0;

	if (SDL_JoystickNumAxes(joys[num]) > 0)
		axis_left = SDL_JoystickGetAxis(joys[num], 0) < -JOY_DEAD_ZONE;

	return axis_left || joy_hat_pressed(num, SDL_HAT_LEFT);
}

static int joy_right(int num)
{
	int axis_right = 0;

	if (!joy_available(num))
		return 0;

	if (SDL_JoystickNumAxes(joys[num]) > 0)
		axis_right = SDL_JoystickGetAxis(joys[num], 0) > JOY_DEAD_ZONE;

	return axis_right || joy_hat_pressed(num, SDL_HAT_RIGHT);
}

static int joy_jump(int num)
{
	int button;
	int button_count;

	if (!joy_available(num))
		return 0;

	button_count = SDL_JoystickNumButtons(joys[num]);
	if (button_count > JOY_FACE_BUTTONS)
		button_count = JOY_FACE_BUTTONS;

	for (button = 0; button < button_count; button++) {
		if (SDL_JoystickGetButton(joys[num], button))
			return 1;
	}

	return 0;
}

int joy_start_pressed(void)
{
	int num;

	for (num = 0; num < num_joys && num < 4; num++) {
		if (joy_available(num) &&
		    SDL_JoystickNumButtons(joys[num]) > JOY_START_BUTTON &&
		    SDL_JoystickGetButton(joys[num], JOY_START_BUTTON))
			return 1;
	}

	return 0;
}

#define JOY_LEFT(num) joy_left(num)
#define JOY_RIGHT(num) joy_right(num)
#define JOY_JUMP(num) joy_jump(num)

int calib_joy(int type)
{
	return 1;
}

void update_player_actions(void)
{
	int tmp;

	if (client_player_num < 0) {
		tmp = (key_pressed(KEY_PL1_LEFT) == 1) || JOY_LEFT(3);
		if (tmp != player[0].action_left)
			tellServerPlayerMoved(0, MOVEMENT_LEFT, tmp);
		tmp = (key_pressed(KEY_PL1_RIGHT) == 1) || JOY_RIGHT(3);
		if (tmp != player[0].action_right)
			tellServerPlayerMoved(0, MOVEMENT_RIGHT, tmp);
		tmp = (key_pressed(KEY_PL1_JUMP) == 1) || JOY_JUMP(3);
		if (tmp != player[0].action_up)
			tellServerPlayerMoved(0, MOVEMENT_UP, tmp);

		tmp = (key_pressed(KEY_PL2_LEFT) == 1) || JOY_LEFT(2);
		if (tmp != player[1].action_left)
			tellServerPlayerMoved(1, MOVEMENT_LEFT, tmp);
		tmp = (key_pressed(KEY_PL2_RIGHT) == 1) || JOY_RIGHT(2);
		if (tmp != player[1].action_right)
			tellServerPlayerMoved(1, MOVEMENT_RIGHT, tmp);
		tmp = (key_pressed(KEY_PL2_JUMP) == 1) || JOY_JUMP(2);
		if (tmp != player[1].action_up)
			tellServerPlayerMoved(1, MOVEMENT_UP, tmp);

		tmp = (key_pressed(KEY_PL3_LEFT) == 1) || JOY_LEFT(1);
		if (tmp != player[2].action_left)
			tellServerPlayerMoved(2, MOVEMENT_LEFT, tmp);
		tmp = (key_pressed(KEY_PL3_RIGHT) == 1) || JOY_RIGHT(1);
		if (tmp != player[2].action_right)
			tellServerPlayerMoved(2, MOVEMENT_RIGHT, tmp);
		tmp = (key_pressed(KEY_PL3_JUMP) == 1) || JOY_JUMP(1);
		if (tmp != player[2].action_up)
			tellServerPlayerMoved(2, MOVEMENT_UP, tmp);

		tmp = (key_pressed(KEY_PL4_LEFT) == 1) || JOY_LEFT(0);
		if (tmp != player[3].action_left)
		tellServerPlayerMoved(3, MOVEMENT_LEFT, tmp);
		tmp = (key_pressed(KEY_PL4_RIGHT) == 1) || JOY_RIGHT(0);
		if (tmp != player[3].action_right)
		tellServerPlayerMoved(3, MOVEMENT_RIGHT, tmp);
		tmp = (key_pressed(KEY_PL4_JUMP) == 1) || JOY_JUMP(0);
		if (tmp != player[3].action_up)
		tellServerPlayerMoved(3, MOVEMENT_UP, tmp);
	} else {
		tmp = (key_pressed(KEY_PL1_LEFT) == 1) || JOY_LEFT(0);
		if (tmp != player[client_player_num].action_left)
			tellServerPlayerMoved(client_player_num, MOVEMENT_LEFT, tmp);
		tmp = (key_pressed(KEY_PL1_RIGHT) == 1) || JOY_RIGHT(0);
		if (tmp != player[client_player_num].action_right)
			tellServerPlayerMoved(client_player_num, MOVEMENT_RIGHT, tmp);
		tmp = (key_pressed(KEY_PL1_JUMP) == 1) || JOY_JUMP(0);
		if (tmp != player[client_player_num].action_up)
			tellServerPlayerMoved(client_player_num, MOVEMENT_UP, tmp);
	}
}

void init_inputs(void)
{
	int i;

	num_joys = SDL_NumJoysticks();
	for(i = 0; i < 4 && i < num_joys; ++i)
		joys[i] = SDL_JoystickOpen(i);

	main_info.mouse_enabled = 0;
	main_info.joy_enabled = 0;
}
